# frozen_string_literal: true

require_relative "tanshuku/configuration"
require_relative "tanshuku/engine"
require_relative "tanshuku/version"

# Tanshuku's namespace.
module Tanshuku
  # Returns a configuration object for Tanshuku.
  #
  # @return [Tanshuku::Configuration]
  def self.config
    Mutex.new.synchronize do
      @config ||= Configuration.new
    end
  end

  # Configures Tanshuku.
  #
  # @yieldparam config [Tanshuku::Configuration] A configuration object that is yielded.
  # @yieldreturn [void]
  #
  # @return [void]
  #
  # @example
  #   Tanshuku.configure do |config|
  #     config.default_url_options = { host: "localhost", protocol: :https }
  #   end
  def self.configure
    yield config
  end
end
