require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  case Gem::Version.new(Rails.version)
  when "7.0"..."7.1"
    config.cache_classes = true
  else
    config.enable_reloading = false
  end

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # noop
  else
    # Cache assets for far-future expiry since they are all digest stamped.
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  end

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
    # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
    # config.require_master_key = true

    case Gem::Version.new(Rails.version)
    when "7.0"..."7.1"
      # Disable serving static files from the `/public` folder by default since
      # Apache or NGINX already handles this.
      config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
    else
      # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
      # config.public_file_server.enabled = false
    end

    # Compress CSS using a preprocessor.
    # config.assets.css_compressor = :sass

    # Do not fallback to assets pipeline if a precompiled asset is missed.
    config.assets.compile = false
  else
    # noop
  end

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # Specifies the header that your server uses for sending files.
    # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
    # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX
  else
    # noop
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # Mount Action Cable outside main process or domain.
    # config.action_cable.mount_path = nil
    # config.action_cable.url = "wss://example.com/cable"
    # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]
  else
    # noop
  end

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
    # config.assume_ssl = true
  else
    config.assume_ssl = true
  end

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  case Gem::Version.new(Rails.version)
  when "7.0"..."7.1"
    # config.force_ssl = true
  else
    config.force_ssl = true
  end

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  case Gem::Version.new(Rails.version)
  when "7.0"..."7.1"
    # Include generic and useful information about system operation, but avoid logging too much
    # information to avoid inadvertent exposure of personally identifiable information (PII).
    config.log_level = :info
  when "7.1"..."8.0"
    # Log to STDOUT by default
    config.logger = ActiveSupport::Logger.new(STDOUT)
      .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
      .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  else
    # noop
  end

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # noop
  else
    config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  end

  case Gem::Version.new(Rails.version)
  when "7.0"..."7.1"
    # noop
  else
    # Change to "debug" to log everything (including potentially personally-identifiable information!)
    config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  end

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # noop
  else
    # Prevent health checks from clogging up the logs.
    config.silence_healthcheck_path = "/up"

    # Don't log any deprecations.
    config.active_support.report_deprecations = false
  end

  # Replace the default in-process memory cache store with a durable alternative.
  # config.cache_store = :mem_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # config.active_job.queue_adapter = :resque

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # Disable caching for Action Mailer templates even if Action Controller
    # caching is enabled.
    config.action_mailer.perform_caching = false
  else
    # noop
  end

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # noop
  else
    # Set host to be used by links generated in mailer templates.
    config.action_mailer.default_url_options = { host: "example.com" }

    # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
    # config.action_mailer.smtp_settings = {
    #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
    #   password: Rails.application.credentials.dig(:smtp, :password),
    #   address: "smtp.example.com",
    #   port: 587,
    #   authentication: :plain
    # }
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # Don't log any deprecations.
    config.active_support.report_deprecations = false
  else
    # noop
  end

  case Gem::Version.new(Rails.version)
  when "7.0"..."7.1"
    # Use default logging formatter so that PID and timestamp are not suppressed.
    config.log_formatter = ::Logger::Formatter.new

    # Use a different logger for distributed setups.
    # require "syslog/logger"
    # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

    if ENV["RAILS_LOG_TO_STDOUT"].present?
      logger           = ActiveSupport::Logger.new(STDOUT)
      logger.formatter = config.log_formatter
      config.logger    = ActiveSupport::TaggedLogging.new(logger)
    end
  else
    # noop
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  case Gem::Version.new(Rails.version)
  when "7.0"..."7.2"
    # noop
  else
    # Only use :id for inspections in production.
    config.active_record.attributes_for_inspect = [ :id ]
  end

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
