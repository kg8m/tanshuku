# frozen_string_literal: true

# A module for utility methods for specs.
module SpecUtilities
  module_function

  SHORTENED_URL_PATTERN = %r{\Ahttp://localhost/t/(\w{20})\z}

  def shorten_and_find_record(url)
    shortened_url = Tanshuku::Url.shorten(url)

    key = shortened_url[SHORTENED_URL_PATTERN, 1]
    Tanshuku::Url.find_by!(key: key)
  end

  def gem_root
    Pathname.new(File.expand_path("../../", __dir__))
  end
end
