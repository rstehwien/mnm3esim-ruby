# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'mnm3esim/version'

Gem::Specification.new do |gem|
  gem.name          = "mnm3esim"
  gem.version       = MnM3eSim::VERSION
  gem.platform      = Gem::Platform::RUBY
  gem.authors       = ["Robert Stehwien"]
  gem.email         = ["rstehwien@arcanearcade.com"]
  gem.description   = %q{Mutants and Masterminds 3E Combat Simulatorn}
  gem.summary       = %q{Mutants and Masterminds 3E Combat Simulator}
  gem.homepage      = "http://arcanearcade.com"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency('rake', '~> 0.9.2.2')
end
