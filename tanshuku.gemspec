# frozen_string_literal: true

require_relative "lib/tanshuku/version"

Gem::Specification.new do |spec|
  spec.name = "tanshuku"
  spec.version = Tanshuku::VERSION
  spec.authors = ["kg8m"]
  spec.email = ["takumi.kagiyama@gmail.com"]

  spec.summary = "Tanshuku is a Rails engine for shortening URLs."
  spec.description =
    "Tanshuku is a Rails engine for shortening URLs. Tanshuku generates a shortened URL per a normalized original URL."
  spec.homepage = "https://github.com/kg8m/tanshuku"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(__dir__) do
      `git ls-files -z`.split("\x0").reject do |f|
        (File.expand_path(f) == __FILE__) || f.match?(%r{\A(?:(?:bin|spec)/|\.git)})
      end
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "addressable", ">= 2.8"
  spec.add_dependency "rails", ">= 7"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
