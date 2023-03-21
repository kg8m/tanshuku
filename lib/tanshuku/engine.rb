# frozen_string_literal: true

module Tanshuku
  # Tanshuku's Rails engine.
  class Engine < ::Rails::Engine
    isolate_namespace Tanshuku

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
