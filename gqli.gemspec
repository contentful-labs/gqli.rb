require File.expand_path('../lib/gqli/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'gqli'
  gem.version       = GQLi::VERSION
  gem.summary       = 'GraphQL client for humans'
  gem.description   = 'GraphQL client with simple interface, designed for developer happiness'
  gem.license       = 'MIT'
  gem.authors       = ['Contentful GmbH (David Litvak Bruno)']
  gem.email         = 'rubygems@contentful.com'
  gem.homepage      = 'https://github.com/contentful-labs/gqli.rb'

  gem.files         = Dir['{**/}{.*,*}'].select { |path| File.file?(path) && !path.start_with?('pkg') }
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ['lib']

  gem.add_dependency 'http', '> 0.8', '< 6.0'
  gem.add_dependency 'hashie', '~> 3.0'
  gem.add_dependency 'multi_json', '~> 1'

  gem.add_development_dependency 'rake', '< 11.0'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'

  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'guard-rubocop'
  gem.add_development_dependency 'guard-yard'
  gem.add_development_dependency 'rubocop', '~> 0.49.1'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'rr'
  gem.add_development_dependency 'vcr'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'webmock', '~> 1', '>= 1.17.3'
  gem.add_development_dependency 'tins', '~> 1.6.0'
end
