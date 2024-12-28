# frozen_string_literal: true

require "rails/generators"

module Tanshuku
  # A generator class for Tanshuku configuration files.
  #
  # @api private
  class InstallGenerator < Rails::Generators::Base
    # Assign `_ = __dir__` because Steep reports `__dir__` which can be a `nil` but I don’t want to care about that.
    source_root File.expand_path("../templates", _ = __dir__)

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
      # rubocop:disable Rails/TimeZone
      old_filename = "20230220123456_create_tanshuku_urls.rb"
      new_filename = old_filename.sub("20230220123456", Time.now.strftime("%Y%m%d%H%M%S"))
      # rubocop:enable Rails/TimeZone

      old_filepath = "../../../db/migrate/#{old_filename}"
      new_filepath = "db/migrate/#{new_filename}"

      copy_file old_filepath, new_filepath

      # rubocop:disable Lint/NumberConversion
      gsub_file new_filepath, "Rails::VERSION::STRING.to_f", Rails::VERSION::STRING.to_f.to_s
      # rubocop:enable Lint/NumberConversion
    end
  end
end
