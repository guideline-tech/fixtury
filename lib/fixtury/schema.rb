# frozen_string_literal: true

require "singleton"
require "fixtury/definition"
require "fixtury/errors/fixture_not_defined_error"
require "fixtury/errors/fixture_already_defined_error"

module Fixtury
  class Schema

    include Singleton

    def self.define(&block)
      if block.arity == 1
        block.call(instance)
      else
        instance.instance_exec(&block)
      end
    end

    attr_reader :definitions

    def initialize
      @definitions = {}
    end

    def get_definition!(name)
      val = get_definition(name)
      raise ::Fixtury::Errors::FixtureNotDefinedError name if val.nil?

      val
    end

    def get_definition(name)
      name = name.to_s
      definitions.fetch(name) { nil }
    end

    def fixture(name, &block)
      name = name.to_s

      if definitions.key?(name)
        raise ::Fixtury::Errors::FixtureAlreadyDefined, name
      end

      definitions[name] = ::Fixtury::Definition.new(self, name, &block)
    end

  end
end
