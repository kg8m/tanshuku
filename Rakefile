# frozen_string_literal: true

require "bundler/setup"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

namespace :yard do
  desc "Start YARD server"
  task :server do
    puts "See http://localhost:8808/"
    sh "yard server --reload"
  end
end
