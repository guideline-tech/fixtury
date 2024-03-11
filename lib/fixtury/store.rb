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

    def inspect
      parts = []
      parts << "schema: #{schema.inspect}"
      parts << "locator: #{locator.inspect}"
      parts << "filepath: #{filepath.inspect}" if filepath
      parts << "ttl: #{ttl.inspect}" if ttl
      parts << "references: #{references.size}"

      "#{self.class}(#{parts.join(", ")})"
    end

    def dump_to_file
      return unless filepath

      ::FileUtils.mkdir_p(File.dirname(filepath))

      writable = references.each_with_object({}) do |(pathname, ref), h|
        h[pathname] = ref if ref.real?
      end

      ::File.binwrite(filepath, writable.to_yaml)
    end

    def load_reference_from_file
      return unless filepath
      return unless File.file?(filepath)

      ::YAML.unsafe_load_file(filepath)
    end

    def clear_stale_references!
      return unless ttl

      references.delete_if do |name, ref|
        stale = reference_stale?(ref)
        log("expiring #{name}", level: LOG_LEVEL_DEBUG) if stale
        stale
      end
    end

    def load_all(schema = self.schema)
      schema.children.each_value do |item|
        get(item.name) if item.acts_like?(:fixtury_definition)
        load_all(item) if item.acts_like?(:fixtury_schema)
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
      ref = references[dfn.pathname]
      result = ref&.real?
      log(result ? "hit #{dfn.pathname}" : "miss #{dfn.pathname}", level: LOG_LEVEL_ALL)
      result
    end

    def loaded_or_loading?(pathname)
      !!references[pathname]
    end

    def maybe_load_isolation_dependencies(definition)
      isolation_key = definition.isolation_key
      return if loaded_isolation_keys[isolation_key]

      load_isolation_dependencies(isolation_key, schema.first_ancestor)
    end

    def load_isolation_dependencies(isolation_key, target_schema)
      loaded_isolation_keys[isolation_key] = true
      target_schema.children.each_value do |child|
        if child.acts_like?(:fixtury_definition)
          next unless child.isolation_key == isolation_key
          next if loaded_or_loading?(child.pathname)
          get(child.pathname)
        elsif child.acts_like?(:fixtury_schema)
          load_isolation_dependencies(isolation_key, child)
        else
          raise NotImplementedError, "Unknown isolation loading behavior: #{child.class.name}"
        end
      end
    end

    # Fetch a fixture by name. This will load the fixture if it has not been loaded yet.
    # If a definition contains an isolation key, all fixtures with the same isolation key will be loaded.
    def get(name)
      log("getting #{name}", level: LOG_LEVEL_DEBUG)

      # Find the definition.
      dfn = schema.get!(name)
      raise ArgumentError, "#{name.inspect} must refer to a definition" unless dfn.acts_like?(:fixtury_definition)

      pathname = dfn.pathname

      # Ensure that if we're part of an isolation group, we load all the fixtures in that group.
      maybe_load_isolation_dependencies(dfn)

      # See if we already hold a reference to the fixture.
      ref = references[pathname]

      # If the reference is a placeholder, we have a circular dependency.
      if ref&.holder?
        raise Errors::CircularDependencyError, pathname
      end

      # If the reference is stale, we should refresh it.
      # We do so by clearing it from the store and setting the reference to nil.
      if ref && reference_stale?(ref)
        log("refreshing #{pathname}", level: LOG_LEVEL_DEBUG)
        clear_reference(pathname)
        ref = nil
      end

      value = nil

      if ref
        log("hit #{pathname}", level: LOG_LEVEL_ALL)
        value = locator.load(ref.locator_key)
        if value.nil?
          clear_reference(pathname)
          ref = nil
          log("missing #{pathname}", level: LOG_LEVEL_ALL)
        end
      end

      if value.nil?
        # set the references to a holder value so any recursive behavior ends up hitting a circular dependency error if the same fixture load is attempted
        references[pathname] = ::Fixtury::Reference.holder(pathname)

        begin
          executor = ::Fixtury::DefinitionExecutor.new(store: self, definition: dfn)
          value = executor.call
        rescue StandardError
          clear_reference(pathname)
          raise
        end

        log("store #{pathname}", level: LOG_LEVEL_DEBUG)

        locator_key = locator.dump(value, context: pathname)
        references[pathname] = ::Fixtury::Reference.new(pathname, locator_key)
      end

      value
    end
    alias [] get

    def clear_reference(pathname)
      references.delete(pathname)
    end

    def reference_stale?(ref)
      return true if ttl && ref.created_at < (Time.now.to_i - ttl)

      !locator.recognizable_key?(ref.locator_key)
    end

    def log(msg, level:)
      ::Fixtury.log(msg, level: level, name: "store")
    end

  end
end
