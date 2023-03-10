# frozen_string_literal: true

require "active_record"
require "addressable"
require "digest/sha2"
require "rack"
require "securerandom"

module Tanshuku
  class Url < ActiveRecord::Base
    DEFAULT_NAMESPACE = ""

    MAX_URL_LENGTH = 10_000
    URL_PATTERN = %r{\A(?:https?://\w+|/)}
    KEY_LENGTH = 20

    validates :url, :hashed_url, :key, presence: true
    validates :url, length: { maximum: MAX_URL_LENGTH }
    validates :url, format: { with: URL_PATTERN }, allow_blank: true

    # Don't validate uniqueness of unique attributes. Raise ActiveRecord::RecordNotUnique instead if the attributes get
    # duplicated. Then rescue the exception and try to retry.
    # validates :url, :hashed_url, :key, uniqueness: true

    def self.shorten(original_url, namespace: DEFAULT_NAMESPACE, url_options: {})
      raise ArgumentError, "original_url should be present" unless original_url

      url = normalize_url(original_url)
      retries = 0

      begin
        transaction do
          record =
            create_or_find_by!(hashed_url: hash_url(url, namespace:)) do |r|
              r.attributes = { url:, key: generate_key }
            end

          record.shortened_url(url_options)
        end
      # ActiveRecord::RecordNotFound is raised when the key is duplicated.
      rescue ActiveRecord::RecordNotFound => e
        if retries < 10
          retries += 1
          retry
        else
          report_exception(exception: e, original_url:)
          original_url
        end
      end
    rescue StandardError => e
      report_exception(exception: e, original_url:)
      original_url
    end

    def self.find_by_url(url, namespace: DEFAULT_NAMESPACE)
      normalized_url = normalize_url(url)
      hashed_url = hash_url(normalized_url, namespace:)

      find_by(hashed_url:)
    end

    # Normalize a trailing slash, `?` for an empty query, and so on, and sort query keys.
    def self.normalize_url(url)
      parsed_url = Addressable::URI.parse(url)
      parsed_url.query_values = Rack::Utils.parse_query(parsed_url.query)
      parsed_url.normalize.to_s
    end

    def self.hash_url(url, namespace: DEFAULT_NAMESPACE)
      Digest::SHA512.hexdigest(namespace.to_s + url)
    end

    def self.generate_key
      SecureRandom.alphanumeric(KEY_LENGTH)
    end

    def self.report_exception(exception:, original_url:)
      Tanshuku.config.exception_reporter.call(exception:, original_url:)
    end

    def shortened_url(url_options = {})
      url_options = url_options.symbolize_keys
      url_options[:controller] = "tanshuku/urls"
      url_options[:action] = :show
      url_options[:key] = key

      Tanshuku::Engine.routes.url_for(url_options)
    end
  end
end
