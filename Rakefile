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
namespace :steep do
  desc "Prepare for typecheck"
  task :prepare do
    sh "bundle exec rbs collection install --frozen"
  end

  desc "Run typecheck"
  task :check do
    sh "bundle exec steep check"
  end
end

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
    require "io/console"

    win_width = IO.console.winsize[1]
    line = "-" * win_width
    exception = nil

    %i[
      rubocop
      spec
      steep:check
      yard:check
    ].each_with_index do |taskname, i|
      puts "" if i.nonzero?
      puts "#{line}\nExecute: #{taskname}\n#{line}\n\n"
      Rake::Task[taskname].invoke
    # rubocop:disable Lint/RescueException
    rescue Exception => e
      case e
      # Abort in some cases, such as insufficient memory or interruption by `<C-c>`.
      # https://ruby-doc.org/3.2.2/Exception.html#class-Exception-label-Built-In+Exception+Classes
      when NoMemoryError, SignalException
        raise
      else
        exception ||= e
      end
    end
    # rubocop:enable Lint/RescueException

    raise exception if exception
  end
end
# rubocop:enable Rails/RakeEnvironment

task default: "check:all"
