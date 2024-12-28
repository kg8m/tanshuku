# frozen_string_literal: true

module CollectPackageFiles
  EXCLUDE_PATHS = %w[Rakefile Steepfile tanshuku.gemspec].freeze
  EXCLUDE_PATTERN = %r{\A(?:\.|Gemfile|rbs_collection|(?:bin|lib/tasks|sig/(?:lib/tasks|patch)|spec|tmp|tools)/)}

  def self.call
    `git ls-files -z`.split("\x0").reject do |f|
      EXCLUDE_PATHS.include?(f) || f.match?(EXCLUDE_PATTERN)
    end
  end
end
