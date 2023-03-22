# frozen_string_literal: true

Tanshuku.configure do |config|
  # Your default URL options for `url_for`. Defaults to `{}`.
  # config.default_url_options = { Your configurations here }

  # Your default error reporter that is used when failed to shorten a URL. Defaults to
  # `Tanshuku::Configuration::DefaultExceptionReporter`. It logs the exception and the original URL with
  # `Rails.logger.warn`. This value should respond to `#call` with keyword arguments `exception:` and `original_url:`.
  # config.exception_reporter =
  #   lambda { |exception:, original_url:|
  #     Your configurations here
  #   }
end
