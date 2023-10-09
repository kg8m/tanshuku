# frozen_string_literal: true

class CreateTanshukuUrls < ActiveRecord::Migration[5.1]
  def change
    create_table :tanshuku_urls do |t|
      t.text :url, null: false
      t.string :hashed_url, null: false, limit: 128, index: { unique: true }, comment: "cf. Tanshuku::Url.hash_url"
      t.string :key, null: false, limit: 20, index: { unique: true }, comment: "cf. Tanshuku::Url.generate_key"
      t.datetime :created_at, null: false, precision: nil
    end
  end
end
