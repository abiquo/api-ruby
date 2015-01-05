# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'abiquo_client/version'

Gem::Specification.new do |gem|
  gem.name          = "abiquo-api"
  gem.version       = AbiquoAPIClient::VERSION
  gem.authors       = ["Marc Cirauqui"]
  gem.email         = ["marc.cirauqui@abiquo.com"]
  gem.description   = %q{Simple Abiquo API client}
  gem.summary       = gem.description

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "excon"
  gem.add_dependency "formatador"
  gem.add_dependency "json"
end