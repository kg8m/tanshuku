# frozen_string_literal: true

module Tanshuku
  class Configuration
    module DefaultExceptionReporter
      def self.call(exception:, original_url:)
        Rails.logger.warn("Tanshuku - Failed to shorten a URL: #{exception.inspect} for #{original_url.inspect}")
      end
    end

    include ActiveModel::Attributes

    attribute :default_url_options, default: {}
    attribute :exception_reporter, default: DefaultExceptionReporter
  end
end
