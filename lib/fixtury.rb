# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/module/delegation"
require "fixtury/version"
require "fixtury/schema"
require "fixtury/locator"
require "fixtury/store"

module Fixtury

  # Shortcut for opening the top level schema.
  def self.define(&block)
    schema.define(&block)
    schema
  end

  # The default top level schema. Fixtury::Schema instances can be completely self-contained but most
  # usage would be through this shared definition.
  def self.schema
    @top_level_schema ||= ::Fixtury::Schema.new(parent: nil, name: "")
  end

end

require "fixtury/railtie" if defined?(Rails)
