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

gem "loofah", "< 2.20"

group :development, :test do
  gem "sprockets-rails"
  gem "sqlite3"
end

group :development do
  gem "paint", require: false

  gem "rubocop", require: false
  gem "rubocop-md", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-thread_safety", require: false

  gem "bump", require: false
  gem "yard", require: false

  # For `yard server`
  gem "thin", require: false
end

group :test do
  gem "rspec"
  gem "rspec-rails"
end
