# frozen_string_literal: true

module Tanshuku
  # Tanshuku's Rails engine.
  #
  # @note
  #   The example below generates a routing +GET `/t/:key` to `Tanshuku::UrlsController#show`+. When your Rails app
  #   receives a request to +/t/abcdefghij0123456789+, +Tanshuku::UrlsController#show+ will be called and a
  #   +Tanshuku::Url+ record with a key +abcdefghij0123456789+ will be found. Then the request will be redirected to the
  #   +Tanshuku::Url+ record's original URL.
  #
  # @example To mount Tanshuku to your Rails app
  #   # config/routes.rb
  #   Rails.application.routes.draw do
  #     mount Tanshuku::Engine, at: "/t"
  #   end
  class Engine < ::Rails::Engine
    isolate_namespace Tanshuku

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
