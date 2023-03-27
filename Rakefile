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

namespace :yard do
  desc "Start YARD server"
  task :server do
    puts "See http://localhost:8808/"
    sh "yard server --reload"
  end

  desc "Check YARD docs"
  task :check do
    sh "yard --no-output --no-cache --fail-on-warning"
  end
end

task default: %i[rubocop spec yard:check]
