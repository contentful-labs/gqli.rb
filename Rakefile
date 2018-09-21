require 'rubygems'

begin
  require 'bundler'
rescue LoadError => e
  warn e.message
  warn 'Run `gem install bundler` to install Bundler.'
  exit -1
end

begin
  Bundler.setup(:development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems.'
  exit e.status_code
end

require 'rake'

require 'rubygems/tasks'
Gem::Tasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new

task rspec_rubocop: %w(spec rubocop)

task test: :spec
task default: :spec
