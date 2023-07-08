# frozen_string_literal: true

require_relative "tanshuku/configuration"
require_relative "tanshuku/engine"
require_relative "tanshuku/version"

# Tanshuku’s namespace.
module Tanshuku
  # Returns a configuration object for Tanshuku.
  #
  # @return [Tanshuku::Configuration]
  #
  # @note
  #   Mutating a {Tanshuku::Configuration} object is thread-<em><b>unsafe</b></em>. It is recommended to use
  #   {Tanshuku.configure} for configuration.
  def self.config
    # Disable this cop but use `Tanshuku::Configuration#configure` for thread-safety.
    # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
    @config ||= Configuration.new
    # rubocop:enable ThreadSafety/InstanceVariableInClassMethod
  end

  # Configures Tanshuku.
  #
  # @yieldparam config [Tanshuku::Configuration] A configuration object that is yielded.
  # @yieldreturn [void]
  #
  # @return [void]
  #
  # @note
  #   This method is thread-safe. When mutating a {Tanshuku::Configuration} object for configuration, it is recommended
  #   to use this method.
  #
  # @example
  #   Tanshuku.configure do |config|
  #     config.default_url_options = { host: "localhost", protocol: :https }
  #   end
  def self.configure(&)
    config.configure(&)
  end
end
