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

gem "sprockets-rails"
gem "sqlite3"

gem "rubocop"
gem "rubocop-md"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"
gem "rubocop-thread_safety"

gem "bump"
gem "yard"

group :test do
  gem "rspec"
  gem "rspec-rails"
end
