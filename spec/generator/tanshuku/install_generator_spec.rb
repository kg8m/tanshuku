# frozen_string_literal: true

require "generators/tanshuku/install_generator"

RSpec.describe Tanshuku::InstallGenerator do
  tests described_class
  destination Dir.mktmpdir(File.basename(__FILE__), SpecUtilities.gem_root.join("tmp"))

  # rubocop:disable Rails/TimeZone
  let(:now) { Time.now }
  # rubocop:enable Rails/TimeZone

  let(:rails_root) { Pathname.new(destination_root) }

  let(:generated_initializer_filepath) do
    rails_root.join("config/initializers/tanshuku.rb")
  end
  let(:generated_migration_filepath) do
    rails_root.join("db/migrate/#{now.strftime("%Y%m%d%H%M%S")}_create_tanshuku_urls.rb")
  end

  before do
    # A directory to `destination_root` will be created. Don’t forget to clean it up.
    prepare_destination

    travel_to now

    expect(generated_initializer_filepath).not_to exist
    expect(generated_migration_filepath).not_to exist
  end

  after do
    # Clean up the directory to `destination_root` created in the `before` hook.
    FileUtils.rm_rf(destination_root)
  end

  it "copies an initializer and a migration to the app" do
    run_generator

    expect(generated_initializer_filepath).to exist
    expect(generated_migration_filepath).to exist

    initializer_content = File.read(gem_root.join("lib/generators/templates/initializer.rb"))
    expect(generated_initializer_filepath.read).to eq initializer_content

    rails_version_string =
      case Gem::Version.new(Rails.version)
      when "7.0"..."7.1"
        "7.0"
      when "7.1"..."7.2"
        "7.1"
      when "7.2"..."8.0"
        "7.2"
      else
        "8.0"
      end
    expect(generated_migration_filepath.read).to eq(<<~RUBY)
      # frozen_string_literal: true

      class CreateTanshukuUrls < ActiveRecord::Migration[#{rails_version_string}]
        def change
          create_table :tanshuku_urls do |t|
            t.text :url, null: false

            # You might adjust the `limit: 128` depending on `Tanshuku.config.url_hasher`.
            t.string :hashed_url, null: false, limit: 128, index: { unique: true }, comment: "cf. Tanshuku::Url.hash_url"

            # You might adjust the `limit: 20` depending on `.key_length` and `.key_generator` of `Tanshuku.config`.
            t.string :key, null: false, limit: 20, index: { unique: true }, comment: "cf. Tanshuku::Url.generate_key"

            t.datetime :created_at, null: false
          end
        end
      end
    RUBY
  end
end
