# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'abiquo-api/version'

Gem::Specification.new do |gem|
  gem.name          = "abiquo-api"
  gem.version       = AbiquoAPIClient::VERSION
  gem.authors       = ["Marc Cirauqui"]
  gem.email         = ["marc.cirauqui@abiquo.com"]
  gem.description   = %q{Simple Abiquo API client}
  gem.homepage      = "https://github.com/abiquo/api-ruby"
  gem.summary       = gem.description

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "excon", '~> 0.43', '>= 0.43.0'
  gem.add_runtime_dependency "faraday", '~> 0.9.2', '>= 0.9.2'
  gem.add_runtime_dependency "faraday_middleware", '~> 0.10.0', '>= 0.10.0'
  gem.add_runtime_dependency "simple_oauth", '~> 0.3.1', '>= 0.3.1'
  gem.add_runtime_dependency "formatador", '~> 0.2', '>= 0.2.5'
  gem.add_runtime_dependency "addressable"
  gem.add_runtime_dependency "json"
end
