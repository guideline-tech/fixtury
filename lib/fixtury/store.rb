# frozen_string_literal: true

require "concurrent/atomic/thread_local_var"
require "fileutils"
require "singleton"
require "yaml"

module Fixtury
  # A store is a container for built fixture references. It is responsible for loading and caching fixtures
  # based on a schema and a locator.
  class Store

    attr_reader :locator
    attr_reader :schema

    def initialize(schema: nil)
      @schema = schema || ::Fixtury.schema
      @locator = ::Fixtury::Locator.from(::Fixtury.configuration.locator_backend)
      self.references = ::Fixtury.configuration.stored_references
    end

    def references
      @references ||= ::Concurrent::ThreadLocalVar.new({})
      @references.value
    end

    def references=(value)
      references.clear
      @references.value = value
    end

    def loaded_isolation_keys
      @loaded_isolation_keys ||= ::Concurrent::ThreadLocalVar.new({})
      @loaded_isolation_keys.value
    end

    # Empty the store of any references and loaded isolation keys.
    def reset
      references.clear
      loaded_isolation_keys.clear
    end

    # Summarize the current state of the store.
    #
    # @return [String]
    def inspect
      parts = []
      parts << "schema: #{schema.inspect}"
      parts << "locator: #{locator.inspect}"
      parts << "ttl: #{ttl.inspect}" if ttl
      parts << "references: #{references.size}"

      "#{self.class}(#{parts.join(", ")})"
    end

    # Clear any references that are beyond their ttl or are no longer recognizable by the locator.
    #
    # @return [void]
    def clear_stale_references!
      references.delete_if do |name, ref|
        stale = reference_stale?(ref)
        log("expiring #{name}", level: LOG_LEVEL_DEBUG) if stale
        stale
      end
    end

    # Load all fixtures in the target schema, defaulting to the store's schema.
    # This will load all fixtures in the schema and any child schemas.
    #
    # @param schema [Fixtury::Schema] The schema to load, defaults to the store's schema.
    # @return [void]
    def load_all(schema = self.schema)
      schema.children.each_value do |item|
        get(item.pathname) if item.acts_like?(:fixtury_definition)
        load_all(item) if item.acts_like?(:fixtury_schema)
      end
    end

    # Temporarily set a contextual schema to use for loading fixtures. This is
    # useful when evaluating dependencies of a definition while still storing the results.
    #
    # @param schema [Fixtury::Schema] The schema to use.
    # @yield [void] The block to execute with the given schema.
    # @return [Object] The result of the block
    def with_relative_schema(schema)
      prior = @schema
      @schema = schema
      yield
    ensure
      @schema = prior
    end

    # Is a fixture for the given search already loaded?
    #
    # @param search [String] The name of the fixture to search for.
    # @return [TrueClass, FalseClass] `true` if the fixture is loaded, `false` otherwise.
    def loaded?(search)
      dfn = schema.get!(search)
      ref = references[dfn.pathname]
      result = ref&.real?
      log(result ? "hit #{dfn.pathname}" : "miss #{dfn.pathname}", level: LOG_LEVEL_ALL)
      result
    end

    # Fetch a fixture by name. This will load the fixture if it has not been loaded yet.
    # If a definition contains an isolation key, all fixtures with the same isolation key will be loaded.
    #
    # @param search [String] The name of the fixture to search for.
    # @return [Object] The loaded fixture.
    # @raise [Fixtury::Errors::CircularDependencyError] if a circular dependency is detected.
    # @raise [Fixtury::Errors::SchemaNodeNotDefinedError] if the search does not return a node.
    # @raise [Fixtury::Errors::UnknownDefinitionError] if the search does not return a definition.
    # @raise [Fixtury::Errors::DefinitionExecutorError] if the definition executor fails.
    def get(search)
      log("getting #{search} relative to #{schema.pathname}", level: LOG_LEVEL_DEBUG)

      # Find the definition.
      dfn = schema.get!(search)
      raise ArgumentError, "#{search.inspect} must refer to a definition" unless dfn.acts_like?(:fixtury_definition)

      pathname = dfn.pathname
      isokey = dfn.isolation_key

      # Ensure that if we're part of an isolation group, we load all the fixtures in that group.
      maybe_load_isolation_dependencies(isokey)

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
          output = executor.call
          value = output.value
        rescue StandardError
          clear_reference(pathname)
          raise
        end

        log("store #{pathname}", level: LOG_LEVEL_DEBUG)

        locator_key = locator.dump(output.value, context: pathname)
        reference_opts = {}
        reference_opts.merge!(output.metadata)
        reference_opts[:isolation_key] = isokey unless isokey == pathname
        references[pathname] = ::Fixtury::Reference.new(
          pathname,
          locator_key,
          **reference_opts
        )
      end

      value
    end
    alias [] get

    protected

    # Determine if the given pathname is already loaded or is currently being loaded.
    #
    # @param pathname [String] The pathname to check.
    # @return [TrueClass, FalseClass] `true` if the pathname is already loaded or is currently being loaded, `false` otherwise.
    def loaded_or_loading?(pathname)
      !!references[pathname]
    end

    # Load all fixtures with the given isolation key in the target schema
    # if we're not already attempting to load them.
    def maybe_load_isolation_dependencies(isolation_key)
      return if loaded_isolation_keys[isolation_key]
      loaded_isolation_keys[isolation_key] = true

      load_isolation_dependencies(isolation_key, schema.first_ancestor)
    end

    # Load all fixtures with the given isolation key in the target schema.
    #
    # @param isolation_key [String] The isolation key to load fixtures for.
    # @param target_schema [Fixtury::Schema] The schema to search within.
    # @return [void]
    def load_isolation_dependencies(isolation_key, target_schema)
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

    # Remove a reference at the given pathname from the stored references.
    #
    # @param pathname [String] The pathname to remove.
    # @return [void]
    def clear_reference(pathname)
      references.delete(pathname)
    end

    # Determine if a reference is stale. A reference is stale if it is beyond its ttl or
    # if it is no longer recognizable by the locator.
    #
    # @param ref [Fixtury::Reference] The reference to check.
    # @return [TrueClass, FalseClass] `true` if the reference is stale, `false` otherwise.
    def reference_stale?(ref)
      return true if ttl && ref.created_at < (Fixtury.now.to_i - ttl)

      !locator.recognizable_key?(ref.locator_key)
    end

    # Log a contextual message using Fixtury.log
    def log(msg, level:)
      ::Fixtury.log(msg, level: level, name: "store")
    end

    def ttl
      ::Fixtury.configuration.reference_ttl&.to_i
    end

  end
end
