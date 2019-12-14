# frozen_string_literal: true

require "fixtury/version"
require "fixtury/path"
require "fixtury/schema"

module Fixtury

  def self.define(name = nil, &block)
    schema = get_schema(name)
    schema.define(&block)
    schema
  end

  def self.get_schema(name = nil)
    @top_level_schemas ||= {}
    @top_level_schemas.fetch(name.to_s) do
      ::Fixtury::Schema.new(parent: nil, name: name.to_s)
    end
  end

  def self.get_definition(name)
    path = ::Fixtury::Path.new(namespace: "", path: name)
    top_level = get_schema(name: path.top_level_namespace)
    top_level.get_definition(name)
  end

  def self.get_namespace(name)
    path = ::Fixtury::Path.new(namespace: "", path: name)
    top_level = get_schema(name: path.top_level_namespace)
    top_level.get_namespace(name)
  end

end
