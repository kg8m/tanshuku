# frozen_string_literal: true

Tanshuku::Engine.routes.draw do
  default_url_options Rails.application.routes.default_url_options.deep_dup

  get "/:key", to: "urls#show"
end
