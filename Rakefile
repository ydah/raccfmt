# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: %i[spec]

desc "Run all tests including integration tests"
task :test do
  Rake::Task[:spec].invoke
end

desc "Run only unit tests"
RSpec::Core::RakeTask.new(:unit) do |t|
  t.rspec_opts = "--tag ~integration"
end

desc "Run only integration tests"
RSpec::Core::RakeTask.new(:integration) do |t|
  t.rspec_opts = "--tag integration"
end

desc "Run performance tests"
RSpec::Core::RakeTask.new(:performance) do |t|
  t.pattern = "spec/performance/**/*_spec.rb"
end

desc "Generate test coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task[:spec].invoke
end
