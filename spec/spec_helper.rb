require 'simplecov'
SimpleCov.start

require 'rspec'
require 'vcr'

Dir[File.join('..', File.dirname(__FILE__), 'lib', '**', '*.rb')].each { |f| require f }

require 'gqli'

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.ignore_localhost = true
  c.hook_into :webmock
  c.default_cassette_options = { record: :once }
end

def vcr(name, &block)
  VCR.use_cassette(name, &block)
end
