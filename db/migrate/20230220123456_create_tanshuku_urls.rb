# frozen_string_literal: true

class CreateTanshukuUrls < ActiveRecord::Migration[Rails::VERSION::STRING.to_f]
  def change
    create_table :tanshuku_urls do |t|
      t.text :url, null: false

      # You might adjust the `limit: 128` depending on `Tanshuku.config.url_hasher`.
      t.string :hashed_url, null: false, limit: 128, index: { unique: true }, comment: "cf. Tanshuku::Url.hash_url"

      # You might adjust the `limit: 20` depending on `.key_length` and `.key_generator` of `Tanshuku.config`.
      t.string :key, null: false, limit: 20, index: { unique: true }, comment: "cf. Tanshuku::Url.generate_key"

      t.datetime :created_at, null: false, precision: nil
    end
  end
end
