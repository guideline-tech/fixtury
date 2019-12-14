# frozen_string_literal: true

require "fixtury/definition"
require "fixtury/path"
require "fixtury/errors/fixture_already_defined_error"
require "fixtury/errors/fixture_not_defined_error"

module Fixtury
  class Schema

    attr_reader :definitions, :children, :name, :parent

    def initialize(parent:, name:)
      @name = name
      @parent = parent
      @children = {}
      @definitions = {}
    end

    def top_level_schema
      top_level_schema? ? self : parent.top_level_schema
    end

    def top_level_schema?
      parent.nil?
    end

    def define(&block)
      instance_eval(&block)
    end

    def namespace(name, &block)
      child = find_or_create_child_schema(name: name)
      child.instance_eval(&block)
      child
    end

    def fixture(name, &block)
      definition = find_child_definition(name: name)
      raise ::Fixtury::Errors::FixtureAlreadyDefinedError, definition.name if definition

      create_child_definition(name: name, &block)
    end

    def enhance(name, &block)
      definition = find_child_definition(name: name)
      raise ::Fixtury::Errors::FixtureNotDefinedError, build_child_name(name: name) unless definition

      definition.enhance(&block)
      definition
    end

    def merge(other_ns)
      other_ns.definitions.each_pair do |name, dfn|
        fixture(name, &dfn.callable)
        dfn.enhancements.each do |e|
          enhance(name, &e)
        end
      end

      other_ns.children.each_pair do |name, other_ns_child|
        namespace(name) do
          merge(other_ns_child)
        end
      end

      self
    end

    def get_definition!(name)
      dfn = get_definition(name)
      raise ::Fixtury::Errors::FixtureNotDefinedError, name unless dfn

      dfn
    end

    def get_definition(name)
      path = ::Fixtury::Path.new(namespace: self.name, path: name)
      top_level = top_level_schema

      dfn = nil
      path.possible_absolute_paths.each do |abs_path|
        *namespaces, definition_name = abs_path.split("/")

        namespaces.shift if namespaces.first == top_level.name
        target = top_level

        namespaces.each do |ns|
          next if ns.empty?

          target = target.children[ns]
          break unless target
        end

        dfn = target.definitions[definition_name] if target
        return dfn if dfn
      end

      nil
    end

    def get_namespace(name)
      path = ::Fixtury::Path.new(namespace: self.name, path: name)
      top_level = top_level_schema

      path.possible_absolute_paths.each do |abs_path|
        *namespaces, _definition_name = abs_path.split("/")

        namespaces.shift if namespaces.first == top_level.name
        target = top_level

        namespaces.each do |ns|
          next if ns.empty?

          target = target.children[ns]
          break unless target
        end

        return target if target
      end

      nil
    end

    protected

    def find_or_create_child_schema(name:)
      name = name.to_s
      children[name] ||= begin
        child_name = build_child_name(name: name)
        self.class.new(name: child_name, parent: self)
      end
    end

    def find_child_definition(name:)
      definitions[name.to_s]
    end

    def create_child_definition(name:, &block)
      child_name = build_child_name(name: name)
      definition = ::Fixtury::Definition.new(name: child_name, schema: self, &block)
      definitions[name.to_s] = definition
    end

    def build_child_name(name:)
      name = name&.to_s
      raise ArgumentError, "`name` must be provided" if name.nil?
      raise ArgumentError, "`name` must contain only a-z, A-Z, 0-9, and _." unless name.match(/^[a-zA-Z_0-9]+$/)

      [self.name, name].join("/")
    end

  end
end
