# frozen_string_literal: true

require "singleton"
require "yaml"
require "fixtury/locator"
require "fixtury/errors/circular_dependency_error"
require "fixtury/execution_context"
require "fixtury/reference"

module Fixtury
  class Store

    cattr_accessor :instance

    HOLDER = "__BUILDING_FIXTURE__"

    attr_reader :filepath, :references, :ttl
    attr_reader :schema, :locator
    attr_reader :verbose
    attr_reader :execution_context

    def initialize(filepath: nil, locator: ::Fixtury::Locator.instance, verbose: false, ttl: nil, schema: nil)
      @schema = schema || ::Fixtury.schema
      @verbose = verbose
      @locator = locator
      @filepath = filepath
      @references = @filepath && ::File.file?(@filepath) ? ::YAML.load_file(@filepath) : {}
      @execution_context = ::Fixtury::ExecutionContext.new
      @ttl = ttl ? ttl.to_i : ttl
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

    def clear_cache!(pattern: nil)
      pattern ||= "*"
      pattern = "/" + pattern unless pattern.start_with?("/")
      glob = pattern.ends_with?("*")
      pattern = pattern[0...-1] if glob
      references.delete_if do |key, _value|
        hit = glob ? key.start_with?(pattern) : key == pattern
        log(true) { "clearing #{key}" } if hit
        hit
      end
      dump_to_file
    end

    def with_relative_schema(schema)
      prior = @schema
      @schema = schema
      yield
    ensure
      @schema = prior
    end

    def loaded?(name)
      dfn = schema.get_definition!(name)
      full_name = dfn.name
      ref = references[full_name]
      result = ref && ref != HOLDER
      log { result ? "hit #{full_name}" : "miss #{full_name}" }
      result
    end

    def get(name)
      dfn = schema.get_definition!(name)
      full_name = dfn.name
      ref = references[full_name]

      if ref == HOLDER
        raise ::Fixtury::Errors::CircularDependencyError, full_name
      end

      ref = ensure_ref_still_relevant(ref)

      value = nil

      if ref
        log { "hit #{name}" }
        value = load_ref(ref.value)
      else
        # set the references to HOLDER so any recursive behavior ends up hitting a circular dependency error if the same fixture load is attempted
        references[full_name] = HOLDER

        value = dfn.call(store: self, execution_context: execution_context)

        log { "store #{name}" }

        ref = dump_ref(full_name, value)
        ref = ::Fixtury::Reference.new(full_name, ref)
        references[full_name] = ref
      end

      value
    end
    alias [] get

    def load_ref(ref)
      locator.load(ref)
    end

    def dump_ref(_name, value)
      locator.dump(value)
    end

    def ensure_ref_still_relevant(ref)
      return ref unless ref
      return ref unless ttl
      return nil unless ref.created_at >= Time.now.to_i - ttl

      ref
    end

    def log(local_verbose = false, &block)
      return unless verbose || local_verbose

      puts "[fixtury|store] #{block.call}"
    end

  end
end
