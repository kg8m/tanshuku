# frozen_string_literal: true

require "English"
require "io/console"
require "paint"
require "pty"

class CheckAll
  TASKNAMES = %i[rubocop spec yard:check].freeze
  LINE = Paint["-" * (IO.console or raise).winsize[1], :bold]
  TITLE_TEMPLATE = Paint["\n#{LINE}\nExecute: %<command>s\n#{LINE}\n\n", :bold]

  attr_reader :failed_commands

  def self.call
    new.call
  end

  def initialize
    @failed_commands = []
  end

  def call
    # rubocop:disable ThreadSafety/NewThread
    TASKNAMES.map { |taskname| Thread.new(taskname, &executor) }.each(&:join)
    # rubocop:enable ThreadSafety/NewThread
    output_result
  end

  private

  def executor
    lambda do |taskname|
      command = "bundle exec rake #{taskname}"

      outputs = []
      outputs << format(TITLE_TEMPLATE, command: command)

      # Use `PTY.spawn` to get colorized outputs of each command.
      PTY.spawn(command) do |reader, writer, pid|
        writer.close

        while (output = reader.gets)
          outputs << output
        end

        Process.wait(pid)
      end
      failed_commands << command unless $CHILD_STATUS&.success?

      puts outputs.join
    end
  end

  def output_result
    puts ""
    puts LINE
    puts Paint["Result", :bold]
    puts LINE

    if failed_commands.empty?
      puts Paint["\nAll checks are OK.", :green, :bold]
    else
      puts Paint["\nChecks failed!!\n", :red, :bold]
      puts failed_commands.map { |command| "  - #{command}" }.join("\n")
      abort ""
    end
  end
end
