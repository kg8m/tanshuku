# frozen_string_literal: true

module Tanshuku
  # A class for managing Tanshuku configurations.
  class Configuration
    # The default error-reporter. Calls +Rails.logger.warn+.
    module DefaultExceptionReporter
      # The default error-reporting procedure. Calls +Rails.logger.warn+.
      #
      # @param exception: [Exception] An error instance at shortening a URL.
      # @param original_url: [String] The original URL failed to shorten.
      #
      # @return [void]
      def self.call(exception:, original_url:)
        Rails.logger.warn("Tanshuku - Failed to shorten a URL: #{exception.inspect} for #{original_url.inspect}")
      end
    end

    include ActiveModel::Attributes

    # @!attribute [rw] default_url_options
    #   Default URL options for Rails' +url_for+. Defaults to +{}+.
    #
    #   @return [Hash]
    #   @return [void] If you set an invalid object.
    #
    #   @note
    #     The example below means that the configured host and protocol are used. Shortened URLs will be like
    #     +https://example.com/t/abcdefghij0123456789+.
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.default_url_options = { host: "example.com", protocol: :https }
    #     end
    attribute :default_url_options, default: {}

    # @!attribute [rw] exception_reporter
    #   A error-reporter class, module, or object used when shortening a URL fails. This should respond to +#call+ with
    #   keyword arguments +exception:+ and +original_url:+. Defaults to
    #   {Tanshuku::Configuration::DefaultExceptionReporter}.
    #
    #   @return [#call] An object that responds to +#call+ with keyword arguments +exception:+ and +original_url:+.
    #   @return [void] If you set an invalid object.
    #
    #   @note The example below means that an exception and a URL will be reported to Sentry (https://sentry.io).
    #
    #   @example
    #     # config/initializers/tanshuku.rb
    #     Tanshuku.configure do |config|
    #       config.exception_reporter =
    #         lambda { |exception:, original_url:|
    #           Sentry.capture_exception(exception, tags: { original_url: })
    #         }
    #     end
    attribute :exception_reporter, default: DefaultExceptionReporter
  end
end
