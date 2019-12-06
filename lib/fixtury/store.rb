# frozen_string_literal: true

require "singleton"
require "file"
require "yaml"
require "fixtury/schema"
require "fixtury/errors/circular_dependency_error"
require "globalid"

module Fixtury
  class Store

    class << self

      def instance
        @instance ||= new
      end

    end

    HOLDER = "__BUILDING_FIXTURE__"

    attr_reader :filepath, :schema, :references

    def initialize(filepath:, schema: ::Fixtury::Schema.instance)
      @schema = schema
      @filepath = filepath
      @references = ::File.file?(@filepath) ? ::YAML.load_file(@filepath) : {}
    end

    def dump_to_file
      ::File.open(filepath, "wb") { |io| io.write(references.to_yaml) }
    end

    def get(name)
      name = name.to_s
      ref = references[name]

      if ref == HOLDER
        raise ::Fixtury::Errors::CircularDependencyError, name
      end

      if ref
        value = load_ref(ref)
        return value if value

        ref = nil
      else
        # set the store to HOLDER so any recursive behavior ends up hitting a circular dependency error if the same fixture load is attempted
        references[name] = HOLDER

        ref = references[name] = begin
          definition = schema.get_definition!(name)
          value = definition.run(self)
          dump_ref(value)
        end
      end

      load_ref(ref)
    end
    alias [] get

    def load_ref(ref)
      ::GlobalID::Locator.locate(ref)
    end

    def dump_ref(value)
      value.to_global_id.to_s
    end

  end
end
