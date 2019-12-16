# frozen_string_literal: true

require "fixtury/version"
require "fixtury/schema"
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/module/delegation"

module Fixtury

  def self.define(&block)
    schema.define(&block)
    schema
  end

  def self.schema
    @top_level_schema ||= ::Fixtury::Schema.new(parent: nil, name: "")
  end

end
