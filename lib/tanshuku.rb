# frozen_string_literal: true

require_relative "tanshuku/configuration"
require_relative "tanshuku/engine"
require_relative "tanshuku/version"

module Tanshuku
  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end
end
