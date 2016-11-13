#uber_array

`UberArray` is an `Array` based datatype that enables SQL-like `where` syntax for arrays of Hashes or Objects.

In Hash based arrays each element is a Hash with symbols or strings as keys.
In Object based arrays each element is an Object-derived instance that responds to attribute names instead of keys.

## Installation

Add this line to your application's Gemfile:

    gem 'uber_array'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install uber_array

## Usage

```ruby
require 'uber_array'

# Array of Hash elements with strings as keys
items = [
  { 'name' => 'Jack', 'score' => 999, 'active' => false },
  { 'name' => 'Jake', 'score' => 888, 'active' => true  },
  { 'name' => 'John', 'score' => 777, 'active' => true  }
]

uber_items = UberArray.new(items)

uber_items.where('name' => 'John')
uber_items.where('name' => /Ja/i)
uber_items.like('ja')
uber_items.where('name' => %w(Dave John Tom))
uber_items.where('score' => 999)
uber_items.where('score' => ->(s){s > 900})
uber_items.where('active' => true, 'score' => 800..900)
uber_items.map_by('name')

Player = Struct.new(:name, :score, :active)

# Array of Object-like Struct elements with attributes
objs = [
  Player.new('Jack', 999, false),
  Player.new('Jake', 888, true),
  Player.new('John', 777, true)
]

uber_objs = UberArray.new(objs, :primary_key => :__name__)

uber_objs.where(:__name__ => 'John')
uber_objs.where(:__name__ => /Ja/i)
uber_objs.like('ja')
uber_objs.where(:__name__ => %w(Dave John Tom))
uber_objs.where(:__score__ => 999)
uber_objs.where(:__score__ => ->(s){s > 900})
uber_objs.where(:__active__ => true, :__score__ => 800..900)
```

### Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request
