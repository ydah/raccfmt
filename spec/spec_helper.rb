# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/vendor/"

    add_group "Rules", "lib/raccfmt/rules"
    add_group "AST", "lib/raccfmt/ast"
    add_group "Core", "lib/raccfmt"
  end
end

require "bundler/setup"
require "raccfmt"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Run specs in random order to surface order dependencies
  config.order = :random

  # Seed global randomization
  Kernel.srand config.seed
end

# Helper methods
def fixture_path(filename)
  File.join(File.dirname(__FILE__), "fixtures", filename)
end

def read_fixture(filename)
  File.read(fixture_path(filename))
end
