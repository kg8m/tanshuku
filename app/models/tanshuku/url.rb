# frozen_string_literal: true

require "active_record"
require "addressable"
require "digest/sha2"
require "rack"
require "securerandom"

module Tanshuku
  # An +ActiveRecord::Base+ inherited class for a shortened URL. This class also have some logics for shortening URLs.
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

    # Shortens a URL. Builds and saves a {Tanshuku::Url} record with generating a unique key for the given URL and
    # namespace. Then returns the record's shortened URL with the given URL options.
    #
    # @note
    #   If a {Tanshuku::Url} record already exists, no additional record will be created and the existing record will be
    #   used.
    # @note
    #   The given URL will be normalized before shortening. So for example, +shorten("https://google.com/")+ and
    #   +shorten("https://google.com")+ have the same result.
    #
    # @param original_url [String] The original, i.e., non-shortened, URL.
    # @param namespace: [String] A namespace for shorteting URL. Shortened URLs are unique in namespaces.
    # @param url_options: [Hash] An option for Rails' +url_for+.
    #
    # @return [String] A shortened URL if succeeded to shorten the original URL.
    # @return [String] The original URL if failed to shorten it.
    #
    # @example If succeeded to shorten a URL.
    #   Tanshuku::Url.shorten("https://google.com/")  #=> "http://localhost/t/abcdefghij0123456789"
    # @example If failed to shorten a URL.
    #   Tanshuku::Url.shorten("https://google.com/")  #=> "https://google.com/"
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

    # Finds a {Tanshuku::Url} record by a non-shortened URL.
    #
    # @param url [String] A non-shortened URL.
    # @param namespace: [String] A namespace for the URL.
    #
    # @return [Tanshuku::Url] A {Tanshuku::Url} instance if found.
    # @reutnr [nil] +nil+ unless found.
    def self.find_by_url(url, namespace: DEFAULT_NAMESPACE)
      normalized_url = normalize_url(url)
      hashed_url = hash_url(normalized_url, namespace:)

      find_by(hashed_url:)
    end

    # Normalizes a URL. Adds or removes a trailing slash, removes +?+ for an empty query, and so on. And sorts query
    # keys.
    #
    # @param url [String] A non-normalized URL.
    #
    # @return [String] A normalized URL.
    def self.normalize_url(url)
      parsed_url = Addressable::URI.parse(url)
      parsed_url.query_values = Rack::Utils.parse_query(parsed_url.query)
      parsed_url.normalize.to_s
    end

    # Hashes a URL with +Digest::SHA512.hexdigest+.
    #
    # @param url [String] A non-hashed URL.
    # @param namespace: [String] A namespace for the URL.
    #
    # @return [String] A hashed 128-character string.
    def self.hash_url(url, namespace: DEFAULT_NAMESPACE)
      Digest::SHA512.hexdigest(namespace.to_s + url)
    end

    # Generates a key with +SecureRandom.alphanumeric+.
    #
    # @return [String] A 20-character alphanumeric string.
    def self.generate_key
      SecureRandom.alphanumeric(KEY_LENGTH)
    end

    # Reports an exception when failed to shorten a URL.
    #
    # @note This method calls {Tanshuku::Configuration#exception_reporter}'s +call+ and returns its return value.
    #
    # @param exception: [Exception] An error instance at shortening a URL.
    # @param original_url: [String] The original URL failed to shorten.
    #
    # @return [void]
    def self.report_exception(exception:, original_url:)
      Tanshuku.config.exception_reporter.call(exception:, original_url:)
    end

    # The record's shortened URL.
    #
    # @param url_options [Hash] An option for Rails' +url_for+.
    #
    # @return [String] A shortened URL.
    def shortened_url(url_options = {})
      url_options = url_options.symbolize_keys
      url_options[:controller] = "tanshuku/urls"
      url_options[:action] = :show
      url_options[:key] = key

      Tanshuku::Engine.routes.url_for(url_options)
    end
  end
end
