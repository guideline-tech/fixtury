# frozen_string_literal: true

module Fixtury
  # A container that manages the execution of a definition in the context of a store.
  class DefinitionExecutor

    attr_reader :value, :definition, :store

    def initialize(store: nil, definition:)
      @store = store
      @definition = definition
      @value = nil
    end

    def call
      run_definition
      value
    end

    private

    # If the callable has a positive arity we generate a DependencyStore
    # and yield it to the callable. Otherwise we just instance_eval the callable.
    # We wrap the actual execution of the definition with a hook for observation.
    def run_definition
      callable = definition.callable

      @value = if callable.arity.positive?
        deps = build_dependency_store
        ::Fixtury.hooks.call(:execution, self) do
          instance_exec(deps, &callable)
        end
      else
        ::Fixtury.hooks.call(:execution, self) do
          instance_eval(&callable)
        end
      end
    rescue Errors::Base
      raise
    rescue => e
      raise Errors::DefinitionExecutionError.new(definition.pathname, e)
    end

    def build_dependency_store
      DependencyStore.new(definition: definition, store: store)
    end

  end
end
