# frozen_string_literal: true

require "active_record"
require "addressable"
require "rack"

module Tanshuku
  # rubocop:disable Rails/ApplicationRecord
  #
  # An +ActiveRecord::Base+ inherited class for a shortened URL. This class also have some logics for shortening URLs.
  class Url < ActiveRecord::Base
    # @!attribute [rw] url
    #   @return [String] Original, i.e., non-shortened, URL of the record.
    #
    # @!attribute [rw] hashed_url
    #   @return [String] A hashed string of the record’s original URL.
    #   @note This attribute is used for uniqueness of the original URL.
    #   @api private
    #
    # @!attribute [rw] key
    #   @return [String] A unique key for the record.
    #
    # @!attribute [rw] created_at
    #   @return [ActiveSupport::TimeWithZone] A timestamp when the record is created.

    DEFAULT_NAMESPACE = ""

    validates :url, :hashed_url, :key, presence: true
    validates :url, length: { maximum: proc { Tanshuku.config.max_url_length } }
    validates :url, format: { with: proc { Tanshuku.config.url_pattern } }, allow_blank: true

    # Don’t validate uniqueness of unique attributes. Raise ActiveRecord::RecordNotUnique instead if the attributes get
    # duplicated. Then rescue the exception and try to retry.
    # validates :url, :hashed_url, :key, uniqueness: true

    # Shortens a URL. Builds and saves a {Tanshuku::Url} record with generating a unique key for the given URL and
    # namespace. Then returns the record’s shortened URL with the given URL options.
    #
    # @note
    #   If a {Tanshuku::Url} record already exists, no additional record will be created and the existing record will be
    #   used.
    # @note
    #   The given URL will be normalized before shortening. So for example, +shorten("https://google.com/")+ and
    #   +shorten("https://google.com")+ have the same result.
    #
    # @param original_url [String] The original, i.e., non-shortened, URL.
    # @param namespace [String] A namespace for shorteting URL. Shortened URLs are unique in namespaces.
    # @param url_options [Hash] An option for Rails’ +url_for+.
    #
    # @return [String] A shortened URL if succeeded to shorten the original URL.
    # @return [String] The original URL if failed to shorten it.
    #
    # @example If succeeded to shorten a URL.
    #   Tanshuku::Url.shorten("https://google.com/")  #=> "http://localhost/t/abcdefghij0123456789"
    # @example If failed to shorten a URL.
    #   Tanshuku::Url.shorten("https://google.com/")  #=> "https://google.com/"
    # @example With ad hoc URL options.
    #   Tanshuku::Url.shorten("https://google.com/", url_options: { host: "verycool.example.com" })
    #   #=> "https://verycool.example.com/t/0123456789abcdefghij"
    #
    #   Tanshuku::Url.shorten("https://google.com/", url_options: { protocol: :http })
    #   #=> "http://example.com/t/abcde01234fghij56789"
    # @example With a namespace.
    #   # When no record exists for “https://google.com/”, a new record will be created.
    #   Tanshuku::Url.shorten("https://google.com/")  #=> "https://example.com/t/abc012def345ghi678j9"
    #
    #   # Even when a record already exists for “https://google.com/”, an additional record will be created if namespace
    #   # is specified.
    #   Tanshuku::Url.shorten("https://google.com/", namespace: "a")  #=> "https://example.com/t/ab01cd23ef45gh67ij89"
    #   Tanshuku::Url.shorten("https://google.com/", namespace: "b")  #=> "https://example.com/t/a0b1c2d3e4f5g6h7i8j9"
    #   Tanshuku::Url.shorten("https://google.com/", namespace: "c")  #=> "https://example.com/t/abcd0123efgh4567ij89"
    #
    #   # When the same URL and the same namespace is specified, no additional record will be created.
    #   Tanshuku::Url.shorten("https://google.com/", namespace: "a")  #=> "https://example.com/t/ab01cd23ef45gh67ij89"
    #   Tanshuku::Url.shorten("https://google.com/", namespace: "a")  #=> "https://example.com/t/ab01cd23ef45gh67ij89"
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
    # @param namespace [String] A namespace for the URL.
    #
    # @return [Tanshuku::Url] A {Tanshuku::Url} instance if found.
    # @return [nil] +nil+ unless found.
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

    # Hashes a URL.
    #
    # @note This method calls {Tanshuku::Configuration#url_hasher}’s +call+ and returns its return value.
    #
    # @param url [String] A non-hashed URL.
    # @param namespace [String] A namespace for the URL.
    #
    # @return [String] Depends on your {Tanshuku::Configuration#url_hasher} configuration.
    def self.hash_url(url, namespace: DEFAULT_NAMESPACE)
      Tanshuku.config.url_hasher.call(url, namespace:)
    end

    # Generates a unique key for a shortened URL.
    #
    # @note This method calls {Tanshuku::Configuration#key_generator}’s +call+ and returns its return value.
    #
    # @return [String] Depends on your {Tanshuku::Configuration#key_generator} configuration.
    def self.generate_key
      Tanshuku.config.key_generator.call
    end

    # Reports an exception when failed to shorten a URL.
    #
    # @note This method calls {Tanshuku::Configuration#exception_reporter}’s +call+ and returns its return value.
    #
    # @param exception [Exception] An error instance at shortening a URL.
    # @param original_url [String] The original URL failed to shorten.
    #
    # @return [void] Depends on your {Tanshuku::Configuration#exception_reporter} configuration.
    def self.report_exception(exception:, original_url:)
      Tanshuku.config.exception_reporter.call(exception:, original_url:)
    end

    # The record’s shortened URL.
    #
    # @param url_options [Hash] An option for Rails’ +url_for+.
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
  # rubocop:enable Rails/ApplicationRecord
end
