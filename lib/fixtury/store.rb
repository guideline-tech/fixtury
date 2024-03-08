# frozen_string_literal: true

require "fileutils"
require "singleton"
require "yaml"

module Fixtury
  class Store

    attr_reader :filepath
    attr_reader :loaded_isolation_keys
    attr_reader :locator
    attr_reader :log_level
    attr_reader :references
    attr_reader :schema
    attr_reader :ttl

    def initialize(filepath: nil, locator: nil, ttl: nil, schema: nil)
      @schema = schema || ::Fixtury.schema
      @locator = locator || ::Fixtury::Locator.new
      @filepath = filepath
      @references = load_reference_from_file || {}
      @ttl = ttl&.to_i
      @loaded_isolation_keys = {}
    end

    def dump_to_file
      return unless filepath

      ::FileUtils.mkdir_p(File.dirname(filepath))

      writable = references.each_with_object({}) do |(full_name, ref), h|
        h[full_name] = ref if ref.real?
      end

      ::File.binwrite(filepath, writable.to_yaml)
    end

    def load_reference_from_file
      return unless filepath
      return unless File.file?(filepath)

      ::YAML.unsafe_load_file(filepath)
    end

    def clear_expired_references!
      return unless ttl

      references.delete_if do |name, ref|
        is_expired = ref_invalid?(ref)
        log("expiring #{name}", level: LOG_LEVEL_DEBUG) if is_expired
        is_expired
      end
    end

    def load_all(schema = self.schema)
      schema.definitions.each_value do |dfn|
        get(dfn.name)
      end

      schema.children.each_value do |ns|
        load_all(ns)
      end
    end

    def clear_cache!(pattern: nil)
      pattern ||= "*"
      pattern = "/#{pattern}" unless pattern.start_with?("/")
      glob = pattern.end_with?("*")
      pattern = pattern[0...-1] if glob
      references.delete_if do |key, _value|
        hit = glob ? key.start_with?(pattern) : key == pattern
        log("clearing #{key}", level: LOG_LEVEL_DEBUG) if hit
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
      dfn = schema.get!(name)
      full_name = dfn.name
      ref = references[full_name]
      result = ref&.real?
      log(result ? "hit #{full_name}" : "miss #{full_name}", level: LOG_LEVEL_ALL)
      result
    end

    def loaded_or_loading?(name)
      dfn = schema.get!(name)
      full_name = dfn.name
      !!references[full_name]
    end

    def maybe_load_isolation_dependencies(definition)
      isolation_key = definition.options[:isolate]

      return if isolation_key.nil?
      return if isolation_key == definition.name
      return if loaded_isolation_keys[isolation_key]

      load_isolation_dependencies(isolation_key, schema)
    end

    def load_isolation_dependencies(isolation_key, target_schema)
      loaded_isolation_keys[isolation_key] = true
      target_schema.definitions.each_value do |dfn|
        next unless dfn.options[:isolate] == isolation_key
        next if loaded_or_loading?(dfn.name)

        get(dfn.name)
      end

      target_schema.children.each_value do |ns|
        load_isolation_dependencies(isolation_key, ns)
      end
    end

    # Fetch a fixture by name. This will load the fixture if it has not been loaded yet.
    # If a definition contains an isolation key, all fixtures with the same isolation key will be loaded.
    def get(name)
      log("getting #{name}", level: LOG_LEVEL_DEBUG)

      # Find the definition.
      dfn = schema.get!(name)
      full_name = dfn.name

      # Ensure that if we're part of an isolation group, we load all the fixtures in that group.
      maybe_load_isolation_dependencies(dfn)

      # See if we already hold a reference to the fixture.
      ref = references[full_name]

      # If the reference is a placeholder, we have a circular dependency.
      if ref&.holder?
        raise Errors::CircularDependencyError, full_name
      end

      # If the reference is stale, we should refresh it.
      # We do so by clearing it from the store and setting the reference to nil.
      if ref && reference_stale?(ref)
        log("refreshing #{full_name}", level: LOG_LEVEL_DEBUG)
        clear_reference(full_name)
        ref = nil
      end

      value = nil

      if ref
        log("hit #{full_name}", level: LOG_LEVEL_ALL)
        value = locator.load(ref.locator_key)
        if value.nil?
          clear_reference(full_name)
          ref = nil
          log("missing #{full_name}", level: LOG_LEVEL_ALL)
        end
      end

      if value.nil?
        # set the references to a holder value so any recursive behavior ends up hitting a circular dependency error if the same fixture load is attempted
        references[full_name] = ::Fixtury::Reference.holder(full_name)

        begin
          value = dfn.call(store: self)
        rescue StandardError
          clear_reference(full_name)
          raise
        end

        log("store #{full_name}", level: LOG_LEVEL_DEBUG)

        locator_key = locator.dump(full_name, value)
        references[full_name] = ::Fixtury::Reference.new(full_name, locator_key)
      end

      value
    end
    alias [] get

    def clear_reference(name)
      references.delete(name)
    end

    def reference_stale?(ref)
      return true if ttl && ref.created_at < (Time.now.to_i - ttl)

      !locator.recognize?(ref.locator_key)
    end

    def log(msg, level:)
      ::Fixtury.log(msg, level: level, name: "store")
    end

    def determine_isolation_key(definition)
      value = definition.options[:isolate]
      case value
      when true
        definition.name
      when String, Symbol
        value.to_s
      else
        nil
      end
    end


  end
end
