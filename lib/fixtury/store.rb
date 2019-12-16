# frozen_string_literal: true

require "singleton"
require "yaml"
require "fixtury/locator"
require "fixtury/errors/circular_dependency_error"

module Fixtury
  class Store

    cattr_accessor :instance

    HOLDER = "__BUILDING_FIXTURE__"

    attr_reader :filepath, :references
    attr_reader :schema, :locator

    def initialize(filepath: nil, locator: ::Fixtury::Locator.instance)
      @schema = ::Fixtury.schema
      @locator = locator
      @filepath = filepath
      @references = @filepath && ::File.file?(@filepath) ? ::YAML.load_file(@filepath) : {}
      self.class.instance ||= self
    end

    def dump_to_file
      return unless filepath

      ::File.open(filepath, "wb") { |io| io.write(references.to_yaml) }
    end

    def load_all(schema = self.schema)
      schema.definitions.each_pair do |_key, dfn|
        get(dfn.name)
      end

      schema.schemas.each_pair do |_key, ns|
        load_all(ns)
      end
    end

    def with_relative_schema(schema)
      prior = @schema
      @schema = schema
      yield
    ensure
      @schema = prior
    end

    def get(name)
      dfn = schema.get_definition!(name)
      full_name = dfn.name
      ref = references[full_name]

      if ref == HOLDER
        raise ::Fixtury::Errors::CircularDependencyError, full_name
      end

      value = nil

      if ref
        value = load_ref(ref)
      else
        # set the references to HOLDER so any recursive behavior ends up hitting a circular dependency error if the same fixture load is attempted
        references[full_name] = HOLDER

        value = dfn.call(store: self)

        references[full_name] = dump_ref(value)
      end

      value
    end
    alias [] get

    def load_ref(ref)
      locator.load(ref)
    end

    def dump_ref(value)
      locator.dump(value)
    end

  end
end
