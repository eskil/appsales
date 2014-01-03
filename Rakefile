$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "bundler"
Bundler.setup

require "rake"
require "rspec"
require "rspec/core/rake_task"

require "appsales/version"

task :build do
  system "gem build appsales.gemspec"
end
