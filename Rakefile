# frozen_string_literal: true

require "bundler/setup"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

# rubocop:disable Rails/RakeEnvironment
namespace :yard do
  desc "Start YARD server"
  task :server do
    sh "bundle exec yard server --reload"
  end

  desc "Check YARD docs"
  task :check do
    sh "bundle exec yard --no-output --no-cache --fail-on-warning"
  end
end

namespace :check do
  desc "Run all checks"
  task :all do
    require "tasks/check_all"
    CheckAll.call
  end
end
# rubocop:enable Rails/RakeEnvironment

task default: "check:all"
