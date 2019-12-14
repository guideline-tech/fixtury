# frozen_string_literal: true

require "fixtury/definition"
require "fixtury/errors/fixture_already_defined_error"
require "fixtury/errors/fixture_not_defined_error"

module Fixtury
  class Namespace

    attr_reader :definitions, :namespaces, :name, :namespace

    def initialize(namespace:, name:)
      @name = name
      @namespace = namespace
      @definitions = {}
      @namespaces = {}
    end

    def top_level_namespace
      top_level_namespace? ? self : namespace.top_level_namespace
    end

    def top_level_namespace?
      namespace.nil?
    end

    def define(&block)
      instance_eval(&block)
    end

    def namespace(name, &block)
      child = find_or_create_child_namespace(name: name)
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
        fixture(name: name, &dfn.callable)
        dfn.enhancements.each do |e|
          enhance(name: name, &e)
        end
      end

      other_ns.namespaces.each_pair do |name, other_ns_child|
        namespace(name: name) do
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
      return find_nested_definition(name) if top_level_namespace?

      top_level_namespace.get_definition(name)
    end

    protected

    def find_nested_definition(_name)
      name = normalize
    end

    def find_or_create_child_namespace(name:)
      name = name.to_s
      namespaces.fetch(name) do
        child_name = build_child_name(name: name)
        self.class.new(name: child_name, namespace: self)
      end
    end

    def find_child_definition(name:)
      definitions[name.to_s]
    end

    def create_child_definition(name:, &block)
      child_name = build_child_name(name: name)
      definition = ::Fixtury::Definition.new(name: child_name, namespace: self, &block)
      definitions[name.to_s] = definition
    end

    def build_child_name(name:)
      raise ArgumentError, "`name` must be provided" if name.nil?

      [self.name, name].join("/")
    end

  end
end
