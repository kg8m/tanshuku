# frozen_string_literal: true

module Tanshuku
  class UrlsController < ActionController::API
    def show
      url = Url.find_by!(key: params[:key])
      redirect_to url.url, status: :moved_permanently, allow_other_host: true
    end
  end
end
