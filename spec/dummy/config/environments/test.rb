# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  case Gem::Version.new(Rails.version)
  when "7.0"..."7.1"
    # Turn false under Spring and add config.action_view.cache_template_loading = true.
    config.cache_classes = true
  else
    # While tests run files are not watched, reloading is not necessary.
    config.enable_reloading = false
  end

  # Eager loading loads your whole application. When running a single test locally,
  # this probably isn't necessary. It's a good idea to do in a continuous integration
  # system, or in some way before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with cache-control for performance.
  case Gem::Version.new(Rails.version)
  when "7.0"..."7.2"
    config.public_file_server.enabled = true
  else
    # noop
  end
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }

  # Show full error reports.
  config.consider_all_requests_local = true

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    config.action_controller.perform_caching = false
  else
    # noop
  end

  config.cache_store = :null_store

  case Gem::Version.new(Rails.version)
  when "7.0"..."7.1"
    # Raise exceptions instead of rendering exception templates.
    config.action_dispatch.show_exceptions = false
  else
    # Render exception templates for rescuable exceptions and raise for other exceptions.
    # config.action_dispatch.show_exceptions = :rescuable
    #
    # Set `:none` for compatibility with Rails 7.0’s behavior.
    config.action_dispatch.show_exceptions = :none
  end

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # Disable caching for Action Mailer templates even if Action Controller
  # caching is enabled.
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  case Gem::Version.new(Rails.version)
  when "7.0"..."7.2"
    # noop
  else
    # Set host to be used by links generated in mailer templates.
    config.action_mailer.default_url_options = { host: "example.com" }
  end

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  case Gem::Version.new(Rails.version)
  when "7.0"..."8.0"
    # Raise exceptions for disallowed deprecations.
    config.active_support.disallowed_deprecation = :raise

    # Tell Active Support which deprecation messages to disallow.
    config.active_support.disallowed_deprecation_warnings = []
  else
    # noop
  end

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  case Gem::Version.new(Rails.version)
  when "7.0"..."7.1"
    # noop
  else
    # Raise error when a before_action's only/except options reference missing actions.
    config.action_controller.raise_on_missing_callback_actions = true
  end
end
