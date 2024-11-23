# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

case Gem::Version.new(Rails.version)
when "7.0"..."7.2"
  # Puma can serve each request in a thread from an internal thread pool.
  # The `threads` method setting takes two numbers: a minimum and maximum.
  # Any libraries that use thread pools should be configured to match
  # the maximum value specified for Puma. Default is set to 5 threads for minimum
  # and maximum; this matches the default thread size of Active Record.
  max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
  min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
  threads min_threads_count, max_threads_count

  rails_env = ENV.fetch("RAILS_ENV") { "development" }

  if rails_env == "production"
    # If you are running more than 1 thread per process, the workers count
    # should be equal to the number of processors (CPU cores) in production.
    #
    # It defaults to 1 because it's impossible to reliably detect how many
    # CPU cores are available. Make sure to set the `WEB_CONCURRENCY` environment
    # variable to match the number of processors.
    worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { 1 })
    if worker_count > 1
      workers worker_count
    else
      preload_app!
    end
  end

  # Specifies the `worker_timeout` threshold that Puma will use to wait before
  # terminating a worker in development environments.
  worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"
else
  # Puma starts a configurable number of processes (workers) and each process
  # serves each request in a thread from an internal thread pool.
  #
  # You can control the number of workers using ENV["WEB_CONCURRENCY"]. You
  # should only set this value when you want to run 2 or more workers. The
  # default is already 1.
  #
  # The ideal number of threads per worker depends both on how much time the
  # application spends waiting for IO operations and on how much you wish to
  # prioritize throughput over latency.
  #
  # As a rule of thumb, increasing the number of threads will increase how much
  # traffic a given process can handle (throughput), but due to CRuby's
  # Global VM Lock (GVL) it has diminishing returns and will degrade the
  # response time (latency) of the application.
  #
  # The default is set to 3 threads as it's deemed a decent compromise between
  # throughput and latency for the average Rails application.
  #
  # Any libraries that use a connection pool or another resource pool should
  # be configured to provide at least as many connections as the number of
  # threads. This includes Active Record's `pool` parameter in `database.yml`.
  threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
  threads threads_count, threads_count
end

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
case Gem::Version.new(Rails.version)
when "7.0"..."7.1"
  environment ENV.fetch("RAILS_ENV") { "development" }
when "7.1"..."7.2"
  environment rails_env
else
  # noop
end

case Gem::Version.new(Rails.version)
when "7.0"..."7.2"
  # Specifies the `pidfile` that Puma will use.
  pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }
else
  # noop
end

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

case Gem::Version.new(Rails.version)
when "7.0"..."7.2"
  # noop
else
  # Specify the PID file. Defaults to tmp/pids/server.pid in development.
  # In other environments, only set the PID file if requested.
  pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
end
