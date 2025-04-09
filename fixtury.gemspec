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
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*"] + Dir["*.gemspec"] + Dir["bin/**/*"]

  spec.bindir        = "bin"
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
