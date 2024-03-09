# frozen_string_literal: true

module Fixtury
  class DefinitionExecutor

    attr_reader :value, :definition, :store

    def initialize(store: nil, definition:)
      @store = store
      @definition = definition
      @value = nil
    end

    def call
      maybe_set_store_context do
        ::Fixtury.hooks.call(:execution, self) do
          run_callable(callable: definition.callable)
        end
      end

      value
    end

    def get(name)
      raise ArgumentError, "A store is required for #{definition.name}" unless store

      store.get(name)
    end
    alias [] get

    private

    def run_callable(callable:)
      @value = if callable.arity.positive?
        instance_exec(self, &callable)
      else
        instance_eval(&callable)
      end
    rescue Errors::Base
      raise
    rescue => e
      raise Errors::DefinitionExecutionError, [definition.name, e], e.backtrace
    end

    def maybe_set_store_context
      return yield unless store

      store.with_relative_schema(definition.parent) do
        yield
      end
    end

  end
end
