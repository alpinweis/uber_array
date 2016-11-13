require 'rspec'
require 'yaml'
require 'uber_array'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def load_fixtures
    file = '../fixtures/items.yml'
    YAML.load_file(File.expand_path(file, __FILE__))
  end
end
