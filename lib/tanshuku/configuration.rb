# frozen_string_literal: true

module Tanshuku
  class Configuration
    include ActiveModel::Attributes

    attribute :default_url_options, default: {}
  end
end
