# frozen_string_literal: true

require "bundler/setup"
require "simplecov"

SimpleCov.start do
  minimum_coverage 95
  add_filter "/spec/"
end

require "property_accessor"

Dir.glob("spec/support/**/*.rb").each(&method(:load))

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.alias_example_to :test
end
