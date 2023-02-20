# frozen_string_literal: true

require_relative "tanshuku/engine"
require_relative "tanshuku/version"

module Tanshuku
  mattr_accessor :default_url_options, default: {}
end
