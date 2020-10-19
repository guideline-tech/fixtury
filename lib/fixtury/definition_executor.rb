# frozen_string_literal: true

module Fixtury
  class DefinitionExecutor

    attr_reader :value, :execution_type, :definition, :store, :execution_context

    def initialize(store: nil, execution_context: nil, definition:)
      @store = store
      @execution_context = execution_context || self
      @definition = definition
      @execution_type = nil
      @value = nil
    end

    def __call
      maybe_set_store_context do
        run_callable(callable: definition.callable, type: :definition)
        definition.enhancements.each do |e|
          run_callable(callable: e, type: :enhancement)
        end
      end
      value
    end

    def get(*args)
      raise ArgumentError, "A store is required for #{definition.name}" unless store

      if execution_context&.respond_to?(:around_fixture_get)
        execution_context.around_fixture_get(self) do
          store.get(*args)
        end
      else
        store.get(*args)
      end
    end
    alias [] get

    private

    def run_callable(callable:, type:)
      @execution_type = type
      provide_execution_context_hooks do
        if callable.arity.positive?
          execution_context.instance_exec(self, &callable)
        else
          execution_context.instance_eval(&callable)
        end
      end
    end

    def provide_execution_context_hooks
      @value = if execution_context.respond_to?(:around_fixture)
        execution_context.around_fixture(self) { yield }
      else
        yield
      end
    end

    def maybe_set_store_context
      return yield unless store

      store.with_relative_schema(definition.schema) do
        yield
      end
    end

  end
end
