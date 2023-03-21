# frozen_string_literal: true

module Tanshuku
  # A Rails controller class for finding a {Tanshuku::Url} record and redirecting to its shortened URL.
  class UrlsController < ActionController::API
    # Finds a {Tanshuku::Url} record from the given +key+ parameter and redirects to its shortened URL.
    #
    # @return [void]
    #
    # @raise [ActiveRecord::NotFound] If no {Tanshuku::Url} record is found for the given +key+.
    def show
      url = Url.find_by!(key: params[:key])
      redirect_to url.url, status: :moved_permanently, allow_other_host: true
    end
  end
end
