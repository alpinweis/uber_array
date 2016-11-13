# -*- encoding: utf-8 -*-
require File.expand_path('../lib/uber_array/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'uber_array'
  spec.version       = UberArray::VERSION
  spec.summary       = 'Array based datatype with SQL-like syntax'
  spec.description   = "Enables SQL-like 'where' syntax for arrays of Hashes or Objects"
  spec.homepage      = 'https://github.com/alpinweis/uber_array'

  spec.authors       = ['Adrian Kazaku']
  spec.email         = ['alpinweis@gmail.com']

  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'rake', '~> 10.1'
  spec.add_development_dependency 'rspec', '~> 3.1'
  # spec.add_development_dependency 'rubocop', '= 0.26.1'
end
