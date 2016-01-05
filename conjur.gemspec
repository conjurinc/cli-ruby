# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafal Rzepecki", "Kevin Gilpin"]
  gem.email         = ["rafal@conjur.net", "kgilpin@conjur.net",]
  gem.summary       = %q{Conjur command line interface}
  gem.homepage      = "https://github.com/conjurinc/cli-ruby"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\) + Dir['build_number']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur-cli"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::VERSION


  gem.add_dependency 'activesupport'
  gem.add_dependency 'conjur-api', '~> 4.20'
  gem.add_dependency 'gli', '>=2.8.0'
  gem.add_dependency 'highline'
  gem.add_dependency 'netrc', '~> 0.10.2'
  gem.add_dependency 'methadone'
  gem.add_dependency 'deep_merge'
  gem.add_dependency 'xdg'
  if RUBY_VERSION > '1.9'
    gem.add_dependency 'iso8601'
  end
  gem.add_runtime_dependency 'cas_rest_client'

  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'aruba', '~> 0.6.1'
  gem.add_development_dependency 'ci_reporter_rspec', '~> 1.0'
  gem.add_development_dependency 'ci_reporter_cucumber'
  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency 'io-grab', '~> 0.0.1'
  gem.add_development_dependency 'json_spec'
end
