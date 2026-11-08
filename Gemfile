# frozen_string_literal: true

source "https://rubygems.org"

gemspec

if ENV.fetch("ADDRESSABLE_VERSION", "") == ""
  gem "addressable"
else
  gem "addressable", ENV.fetch("ADDRESSABLE_VERSION")
end

if ENV.fetch("RAILS_VERSION", "") == ""
  gem "rails"
else
  gem "rails", ENV.fetch("RAILS_VERSION")
end

# For Ruby 3.4+
#
#   warning: ... was loaded from the standard library, but is not part of the default gems starting from Ruby 3.4.0.
#
#   'Kernel.require': cannot load such file -- ... (LoadError)
gem "base64"
gem "benchmark"
gem "bigdecimal"
gem "drb"
gem "mutex_m"

group :development, :test do
  gem "propshaft"

  gem "sqlite3"
end

group :development do
  gem "steep", require: false

  gem "paint", require: false

  gem "rubocop", require: false
  gem "rubocop-md", require: false
  gem "rubocop-on-rbs", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
  gem "rubocop-thread_safety", require: false
  gem "rubocop-yard", require: false

  gem "bump", require: false
  gem "yard", require: false

  # For `yard server`
  gem "puma", require: false
end

group :test do
  gem "rspec"
  gem "rspec-rails"
end
