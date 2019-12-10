# frozen_string_literal: true

require "fixtury/definition"
require "fixtury/errors/fixture_not_defined_error"
require "fixtury/errors/fixture_already_defined_error"

module Fixtury
  class Schema

    DEFAULT_SCHEMA_NAME = "__fixtury_default__"

    class << self

      def define(name: nil, &block)
        get_schema(name: name).define(&block)
      end

      def get_schema(name: nil)
        name ||= DEFAULT_SCHEMA_NAME
        @schemas ||= {}
        @schemas.fetch(name.to_s) { new }
      end

      # not a true singleton, just a default instance
      alias instance get_schema

    end

    attr_reader :definitions, :namespaces

    def initialize
      @definitions = {}
      @namespaces = []
    end

    def define(namespace: nil, &block)
      maybe_namespace name: namespace do
        if block.arity == 1
          block.call(self)
        else
          instance_eval(&block)
        end
      end
    end

    def get_definition!(name:)
      val = get_definition(name: name)
      raise ::Fixtury::Errors::FixtureNotDefinedError name if val.nil?

      val
    end

    def get_definition(name:)
      name = name.to_s
      definitions.fetch(name) { nil }
    end

    def fixture(name:, &block)
      name = [*namespaces, name.to_s].join(".")

      if definitions.key?(name)
        raise ::Fixtury::Errors::FixtureAlreadyDefinedError, name
      end

      definitions[name] = ::Fixtury::Definition.new(name: name, callable: block)
    end

    def namespace(name:, &block)
      @namespaces << name.to_s
      define(&block)
    ensure
      @namespaces.pop
    end

    protected

    def maybe_namespace(name:)
      return yield if name.nil?

      namespace(name: name) do
        yield
      end
    end

  end
end
