# frozen_string_literal: true

require "rails/generators"

module Tanshuku
  # A generator class for Tanshuku configuration files.
  #
  # @api private
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __dir__)

    # Generates a configuration file +config/initializers/tanshuku.rb+.
    #
    # @return [void]
    def copy_initializer_file
      copy_file "initializer.rb", "config/initializers/tanshuku.rb"
    end

    # Generates a migration file +db/migrate/20230220123456_create_tanshuku_urls.rb+.
    #
    # @return [void]
    def copy_migration_file
      filename = "20230220123456_create_tanshuku_urls.rb"
      copy_file "../../../db/migrate/#{filename}", "db/migrate/#{filename}"
    end
  end
end
