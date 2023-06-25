# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../spec/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../spec/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
ActiveRecord::Migration.maintain_test_schema!
require "rspec/rails"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = "#{ActiveSupport::TestCase.fixture_path}/files"
  ActiveSupport::TestCase.fixtures :all
end

require_relative "support/spec_utilities"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.infer_spec_type_from_file_location!

  config.use_transactional_fixtures = true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include ActiveSupport::Testing::Assertions
  config.include ActiveSupport::Testing::TimeHelpers
  config.include SpecUtilities

  # `Rails::Generators::Testing::Behaviour` expects `FileUtils` to be included in generator tests.
  config.include FileUtils, type: :generator

  require "rails/generators/testing/behaviour"
  config.include Rails::Generators::Testing::Behaviour, type: :generator
end
