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
    attribute :default_url_options, default: {}

    # @!attribute [rw] exception_reporter
    #   A error-reporter class, module, or object used when shortening a URL fails. This should respond to +#call+.
    #   Defaults to {Tanshuku::Configuration::DefaultExceptionReporter}.
    #
    #   @return [Tanshuku::Configuration::DefaultExceptionReporter, #call]
    #     A +Tanshuku::Configuration::DefaultExceptionReporter+ instance or an object that responds to +#call+.
    #   @return [void] If you set an invalid object.
    attribute :exception_reporter, default: DefaultExceptionReporter
  end
end
