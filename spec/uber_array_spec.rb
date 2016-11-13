module UberArraySpec

  class Item
    def initialize(options = {})
      options.each do |key, val|
        instance_variable_set("@#{key}", val)
        self.class.send(:attr_reader, key.to_sym)
      end
    end
  end

  describe UberArray do
    # each array element is a Hash with string key names
    let(:items_str) { load_fixtures }
    # each array element is a Hash with symbolized key names
    let(:items_sym) { items_str.map { |i| Hash[i.map { |(k, v)| [k.to_sym, v] }] } }
    # each array element is an Item object with attributes instead of key names
    let(:items_obj) { items_str.map { |i| Item.new(i) } }

    # UberArray instances
    subject(:array_sym) { UberArray.new(items_sym) }
    subject(:array_str) { UberArray.new(items_str) }
    subject(:array_obj) { UberArray.new(items_obj) }

    let(:names) { items_sym.map { |i| i[:name] } }
    let(:name)  { 'Sandi' }

    it 'delegates to the inner Array' do
      expect(array_sym.respond_to?(:size)).to be false
      expect(array_sym.size).to eq(5)
    end

    it 'returns an UberArray when resulting elements are of the same type' do
      expect(array_str.reverse).to be_a UberArray
      expect(array_sym.sample(2)).to be_a UberArray
      expect(array_sym.select { |i| i[:active] }).to be_a UberArray
      expect(array_obj.select { |i| i.active }).to be_a UberArray
    end

    it 'returns a regular Array when resulting elements are of a different type' do
      expect(array_str.map { |i| Item.new(i) }).not_to be_a UberArray
    end

    describe '#method_name?' do
      it 'extracts method name' do
        [
          # input_key => result
          [:__name__, :name],
          [:___name___, :_name_],
          [:_name_, nil],
          ['__name__', nil]
        ].each { |key, rez| expect(array_sym.method_name?(key)).to eq rez }
      end
    end

    describe '#map_by' do
      it 'maps by string' do
        expect(array_str.map_by('name')).to eq names
      end

      it 'maps by symbol' do
        expect(array_sym.map_by(:name)).to eq names
      end

      it 'maps by attribute name' do
        expect(array_obj.map(&:name)).to eq names
      end
    end

    describe '#where' do
      it 'filters by {string => String}' do
        # where item['name'] equals name
        expect(array_str.where('name' => name).array).to eq items_str.values_at(3)
        expect(array_sym.where('name' => name).array).to be_empty
        expect(array_obj.where('name' => name).array).to be_empty
      end

      it 'filters by {:symbol => String}' do
        # where item['name'] equals name
        expect(array_str.where(:name => name).array).to be_empty
        expect(array_sym.where(:name => name).array).to eq items_sym.values_at(3)
        expect(array_obj.where(:name => name).array).to be_empty
      end

      it 'filters by {:__symbol__ => String}' do
        # where item.name equals name
        expect(array_str.where(:__name__ => name).array).to be_empty
        expect(array_sym.where(:__name__ => name).array).to be_empty
        expect(array_obj.where(:__name__ => name).array).to eq items_obj.values_at(3)
      end

      it 'filters by {key => Regexp}' do
        regex = /test/
        # where item['email'] is like regex
        expect(array_str.where('email' => regex).array).to eq items_str.values_at(0, 4)
        expect(array_sym.where(:email  => regex).array).to eq items_sym.values_at(0, 4)
        expect(array_obj.where(:__email__ => regex).array).to eq items_obj.values_at(0, 4)
      end

      it 'filters by {key => Boolean}' do
        # where item['admin'] is true
        expect(array_str.where('admin' => true).array).to eq items_str.values_at(4)
        expect(array_sym.where(:admin  => true).array).to eq items_sym.values_at(4)
        expect(array_obj.where(:__admin__ => true).array).to eq items_obj.values_at(4)
        # where item['active'] is false
        expect(array_str.where('active' => false).array).to eq items_str.values_at(1, 3)
        expect(array_sym.where(:active  => false).array).to eq items_sym.values_at(1, 3)
        expect(array_obj.where(:__active__ => false).array).to eq items_obj.values_at(1, 3)
      end

      it 'filters by {key => Proc}' do
        prok = ->(score) { score > 900 }
        # where item['score'] < 900
        expect(array_str.where('score' => prok).array).to eq items_str.values_at(4)
        expect(array_sym.where(:score  => prok).array).to eq items_sym.values_at(4)
        expect(array_obj.where(:__score__ => prok).array).to eq items_obj.values_at(4)
      end

      it 'filters by {key => Range}' do
        range = 500..700
        # where item['score'] is in range
        expect(array_str.where('score' => range).array).to eq items_str.values_at(2, 3)
        expect(array_sym.where(:score  => range).array).to eq items_sym.values_at(2, 3)
        expect(array_obj.where(:__score__ => range).array).to eq items_obj.values_at(2, 3)
      end

      it 'filters by {key => Array}' do
        teams = %w(bots ninjas)
        # where item['team'] is a member of teams
        expect(array_str.where('team' => teams).array).to eq items_str.values_at(0, 4)
        expect(array_sym.where(:team  => teams).array).to eq items_sym.values_at(0, 4)
        expect(array_obj.where(:__team__ => teams).array).to eq items_obj.values_at(0, 4)
      end

      it 'filters by multiple criteria' do
        # where item['active'] is true AND item['score'] < 700
        filter = { 'active' => true, 'score' => ->(s) { s < 700 } }
        expect(array_str.where(filter).array).to eq items_str.values_at(2)
        # where item[:team] equals team AND item[:admin] is true
        filter = { :team => 'ninjas', :admin => true }
        expect(array_sym.where(filter).array).to eq items_sym.values_at(4)
        # where item.email is like regex AND item.phone['sms'] is not nil
        filter = { :__email__ => /test/, :__phone__ => ->p { p['sms'] } }
        expect(array_obj.where(filter).array).to eq items_obj.values_at(0)
      end

      it 'supports chaining' do
        team = 'ninjas'
        expect(array_sym.where(active: true).where(team: team).array).to eq items_sym.values_at(0, 4)
      end
    end

    describe '#like' do
      it 'filters by regex matching on primary_key' do
        ['an', /an/i].each do |regex|
          # where item['name'] =~ regex
          expect(array_str.like(regex).array).to eq items_str.values_at(2, 3)
        end
      end
    end

    describe '#[]' do
      it 'references elements by index' do
        expect(array_str[1]).to eq items_str[1]
      end

      it "references items by the value of primary_key 'name'" do
        # primary_key is a string key 'name' by default
        expect(array_str[name]).to eq array_str[3]
        expect(array_sym[name]).to eq nil
        expect(array_obj[name]).to eq nil
      end

      it 'references items by the value of primary_key :name' do
        # primary_key is a symbol key :name
        [array_str, array_sym, array_obj].each { |a| a.primary_key = :name }
        expect(array_str[name]).to eq nil
        expect(array_sym[name]).to eq array_sym[3]
        expect(array_obj[name]).to eq nil
      end

      it 'references items by the value of primary_key :__name__' do
        # primary_key is an attribute :__name__
        [array_str, array_sym, array_obj].each { |a| a.primary_key = :__name__ }
        expect(array_str[name]).to eq nil
        expect(array_sym[name]).to eq nil
        expect(array_obj[name]).to eq array_obj[3]
      end

      it 'references items by the value of primary_key :id' do
        id = '3d'
        # primary_key is a symbol key :id
        [array_str, array_sym, array_obj].each { |a| a.primary_key = :id }
        expect(array_str[id]).to eq nil
        expect(array_sym[id]).to eq array_sym[3]
        expect(array_obj[id]).to eq nil
      end
    end
  end
end
