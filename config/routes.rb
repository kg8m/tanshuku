# frozen_string_literal: true

Tanshuku::Engine.routes.draw do
  default_url_options Tanshuku.config.default_url_options

  get "/:key", to: "urls#show"
end
