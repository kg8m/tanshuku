# frozen_string_literal: true

require_relative "lib/tanshuku/version"
require_relative "tools/collect_package_files"

Gem::Specification.new do |spec|
  spec.name = "tanshuku"
  spec.version = Tanshuku::VERSION
  spec.authors = ["kg8m"]
  spec.email = ["takumi.kagiyama@gmail.com"]

  spec.summary = "Tanshuku is a simple and performance aware Rails engine for shortening URLs."
  spec.description = <<~TXT.strip.tr("\n", " ")
    Tanshuku is a simple and performance aware Rails engine for shortening URLs.
    Tanshuku generates a shortened URL per a normalized original URL.
    Tanshuku redirects from a shortened URL to its corresponding original URL.
  TXT
  spec.homepage = "https://github.com/kg8m/tanshuku"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/releases"
  spec.metadata["documentation_uri"] = "https://kg8m.github.io/tanshuku/"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = CollectPackageFiles.call
  spec.require_paths = ["lib"]

  spec.add_dependency "addressable", ">= 2.4"
  spec.add_dependency "rails", ">= 7.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
