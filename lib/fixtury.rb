# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/module/delegation"
require "fixtury/version"
require "fixtury/schema"
require "fixtury/locator"
require "fixtury/store"
require "fixtury/execution_context"

module Fixtury

  def self.define(&block)
    schema.define(&block)
    schema
  end

  def self.schema
    @top_level_schema ||= ::Fixtury::Schema.new(parent: nil, name: "")
  end

end

require "fixtury/railtie" if defined?(Rails)
