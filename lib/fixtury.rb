# frozen_string_literal: true

require "fixtury/version"

module Fixtury

  def self.define(name: nil, &block)
    get_schema(name: name).define(&block)
  end

  def self.get_schema(name: nil)
    @top_level_namespaces ||= {}
    @top_level_namespaces.fetch(name.to_s) do
      ::Fixtury::Namespace.new(namespace: nil, name: name.to_s)
    end
  end

end
