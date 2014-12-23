# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tufts_data_normalization/version'

Gem::Specification.new do |spec|
  spec.name          = "tufts_data_normalization"
  spec.version       = TuftsDataNormalization::VERSION
  spec.authors       = ["Mike Korcynski"]
  spec.email         = ["mkorcy@gmail.com"]
  spec.description   = "A Gem with tasks for normalizing Tufts Fedora Repository Objects"
  spec.summary          = "Tufts Data Normalization"
  spec.homepage      = ""

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "engine_cart"
  spec.add_development_dependency "devise", ">= 3.4.0"

  spec.add_dependency "railties", ">= 3.2", '< 5'
  spec.add_dependency "active-fedora", "~> 7.0"
  spec.add_dependency "chronic"
  spec.add_dependency "hydra-core"
  spec.add_dependency "hydra-role-management"
  spec.add_dependency "titleize"
  spec.add_dependency "settingslogic"
end
