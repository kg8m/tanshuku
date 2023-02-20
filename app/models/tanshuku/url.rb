# frozen_string_literal: true

require "active_record"
require "addressable"
require "digest/sha2"
require "rack"
require "securerandom"

module Tanshuku
  class Url < ActiveRecord::Base
    MAX_URL_LENGTH = 10_000
    URL_PATTERN = %r{\A(?:https?:/)?/\w+}
    KEY_LENGTH = 20

    validates :url, :hashed_url, :key, presence: true
    validates :url, length: { maximum: MAX_URL_LENGTH }
    validates :url, format: { with: URL_PATTERN }

    # Don't validate uniqueness of unique attributes. Raise ActiveRecord::RecordNotUnique instead if the attributes get
    # duplicated. Then rescue the exception and try to retry.
    # validates :url, :hashed_url, :key, uniqueness: true

    def self.shorten(original_url, retries: 0)
      url = normalize_url(original_url)

      record =
        create_or_find_by!(hashed_url: hash_url(url)) do |r|
          r.attributes = { url:, key: generate_key }
        end

      record.shortened_url
    rescue ActiveRecord::RecordNotUnique => e
      if retries < 10
        shorten(url, retries: retries + 1)
      else
        report_exception(exception: e, original_url:)
        original_url
      end
    rescue StandardError => e
      report_exception(exception: e, original_url:)
      original_url
    end

    # Normalize a trailing slash, `?` for an empty query, and so on, and sort query keys.
    def self.normalize_url(url)
      parsed_url = Addressable::URI.parse(url)
      parsed_url.query_values = Rack::Utils.parse_query(parsed_url.query)
      parsed_url.normalize.to_s
    end

    def self.hash_url(url)
      Digest::SHA512.hexdigest(url)
    end

    def self.generate_key
      SecureRandom.alphanumeric(KEY_LENGTH)
    end

    def self.report_exception(exception:, original_url:)
      logger.warn("Tanshuku - Failed to shorten a URL: #{exception.inspect} for #{original_url.inspect}")
    end

    def shortened_url
      Tanshuku::Engine.routes.url_for(controller: "tanshuku/urls", action: :show, key:)
    end
  end
end
