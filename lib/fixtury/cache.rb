# frozen_string_literal: true

require "singleton"
require "yaml"
require "fixtury/locator"
require "fixtury/errors/circular_dependency_error"

module Fixtury
  class Cache

    HOLDER = "__BUILDING_FIXTURE__"

    attr_reader :filepath, :references
    attr_reader :namespace, :locator

    def initialize(filepath: nil, namespace: ::Fixtury::Schema.get_schema, locator: ::Fixtury::Locator.instance)
      @namespace = namespace
      @locator = locator
      @filepath = filepath
      @references = @filepath && ::File.file?(@filepath) ? ::YAML.load_file(@filepath) : {}
    end

    def dump_to_file
      return unless filepath

      ::File.open(filepath, "wb") { |io| io.write(references.to_yaml) }
    end

    def load_all(namespace = self.namespace)
      namespace.definitions.each_pair do |_key, dfn|
        get(dfn.name)
      end

      namespace.namespaces.each_pair do |_key, ns|
        load_all(ns)
      end
    end

    def get(name)
      name = name.to_s
      ref = references[name]

      if ref == HOLDER
        raise ::Fixtury::Errors::CircularDependencyError, name
      end

      value = nil

      if ref
        value = load_ref(ref)
      else
        # set the references to HOLDER so any recursive behavior ends up hitting a circular dependency error if the same fixture load is attempted
        references[name] = HOLDER

        dfn = namespace.get_definition!(name: name)
        value = dfn.call(cache: self)

        references[name] = dump_ref(value)
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
