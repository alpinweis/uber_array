class UberArray
  attr_accessor :array, :primary_key

  # @param array [Array<Hash|Object>] underlying array
  # @param options [Hash] init options
  # @option options [String|Symbol] :primary_key Name of primary key or attribute
  #   attribute/method names are specified as symbols like :__name__
  def initialize(array = [], options = {})
    @array = array || []
    @primary_key = options[:primary_key] || 'name'
  end

  # get current config options
  def uberopts
    { primary_key: primary_key }
  end

  # delegate all methods to the inner @array,
  # if the result is an Array with elements of the same type as @array - convert it to UberArray
  def method_missing(method, *args, &block)
    klass = @array.first.class
    result = @array.send(method, *args, &block)
    if result.is_a?(Array)
      @array.empty? || result.empty? || result.first.class == klass ? UberArray.new(result, uberopts) : result
    else
      result
    end
  end

  # @param key [String|Symbol] key name to map by
  def map_by(key)
    @array.map { |i| i[key] }
  end

  # build a Proc by which to filter items in @array
  # @params opts [Hash] filter options
  def filter_proc(opts = {})
    fail ArgumentError, 'Hash argument expected' unless opts.is_a?(Hash)

    if opts.empty?
      -> { false }
    else
      lambda do |item|
        opts.map do |key, val|
          can_respond, ival = item_send_if_respond_to?(item, key)
          can_respond &&
          case val
          # :key => ->(v){v > 12}
          when Proc
            val.call(ival)
          # :key => /text/
          when Regexp
            ival =~ val
          # :key => 1..4, :key => [1,2,3,4]
          when Array, Range
            val.to_a.include?(ival)
          # :key => false|true, :key => 'text', :key => 10
          else
            ival == val
          end
        end.all?
      end
    end
  end

  # check if key represents a method/attribute name and return it if so
  # @param key [String|Symbol] key name
  def method_name?(key)
    key.is_a?(Symbol) && /^__(?<name>.+)__$/ =~ key ? name.to_sym : nil
  end

  # check if item responds to a given key/attribute name
  def item_respond_to?(item, key)
    method = method_name?(key) || :[]
    item.respond_to?(method)
  end

  # invoke the given key/attribute name as a method on item
  def item_send(item, key)
    method = method_name?(key)
    method ? item.send(method) : item[key]
  end

  # send a key/method name to an item if the item responds to it
  # @param item [Hash|Object] item of @array
  # @param key [String|Symbol] key name
  def item_send_if_respond_to?(item, key)
    can_respond, result = nil, nil
    method = method_name?(key)
    if method
      can_respond = item.respond_to?(method)
      result = item.send(method) if can_respond
    else
      can_respond = item.respond_to?(:[])
      result = item[key] if can_respond
    end
    [can_respond, result]
  end

  # filter items in @array
  # @params opts [Hash] filter options
  # Keys are key names (e.g. :name, 'name') for Hash-based elements
  # or attribute names (e.g. :__name__) for Object-based elements
  def where(opts = {})
    return UberArray.new([], uberopts) if opts.empty?
    result = @array.select(&filter_proc(opts))
    UberArray.new(result, uberopts)
  end
  alias_method :filter, :where

  # filter items by regex matching on @primary_key
  def like(regex)
    exp = regex.is_a?(String) ? Regexp.new(regex, true) : regex
    where(primary_key => exp)
  end

  # use a non-number as access key into @array
  # with elements responding to a key or attribute name specified by @primary_key
  def [](key)
    return @array[key] if key.is_a?(Fixnum)
    method = method_name?(primary_key)
    @array.find do |item|
      if method
        item.respond_to?(method) && item.send(method) == key
      else
        item.respond_to?(:[]) && item[primary_key] == key
      end
    end
  end
end
