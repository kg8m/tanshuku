# frozen_string_literal: true

require "bundler"
require "forwardable"

module ReverseDependencies
  def self.tanshuku_depends_on?(gem_name)
    parse.fetch(gem_name).tanshuku_depends_on?
  end

  class << self
    private

    def parse
      lockfile_parser.specs.each_with_object({}) do |spec, parsed|
        parsed[spec.name] ||= Specification.new(spec.name)
        spec.dependencies.each do |dependency|
          parsed[dependency.name] ||= Specification.new(dependency.name)
          parsed[dependency.name].add_reversed_dependency(parsed[spec.name])
        end
      end
    end

    def lockfile_parser
      Bundler::LockfileParser.new(lockfile_content)
    end

    def lockfile_content
      File.read(Bundler.default_lockfile)
    end
  end

  class Specification
    extend Forwardable
    delegate hash: :name

    attr_reader :name

    def initialize(name)
      @name = name
      @reversed_dependencies = Set.new
    end

    def ==(other)
      other.instance_of?(self.class) && other.name == name
    end
    alias eql? ==

    def add_reversed_dependency(specification)
      reversed_dependencies << specification
    end

    def tanshuku?
      name == "tanshuku"
    end

    def tanshuku_depends_on?
      reversed_dependencies.any?(&:tanshuku?) || reversed_dependencies.any?(&:tanshuku_depends_on?)
    end

    private

    attr_reader :reversed_dependencies
  end
end
