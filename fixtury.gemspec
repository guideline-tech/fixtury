# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "fixtury/version"

Gem::Specification.new do |spec|
  spec.name          = "fixtury"
  spec.version       = Fixtury::VERSION
  spec.authors       = ["Mike Nelson"]
  spec.email         = ["mike@guideline.com"]

  spec.summary       = "Treat fixtures like factories and factories like fixtures"
  spec.homepage      = "https://github.com/guideline-tech/fixtury"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "globalid"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "m"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"

  spec.required_ruby_version = ">= 3.2.0"
end
