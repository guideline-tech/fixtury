# frozen_string_literal: true

module Fixtury
  class DefinitionExecutor

    attr_reader :value, :execution_type, :definition, :store, :execution_context

    def initialize(store: nil, execution_context: nil, definition:)
      @store = store
      @definition = definition
      @execution_context = execution_context
      @execution_type = nil
      @value = nil
    end

    def __call
      maybe_set_store_context do
        provide_schema_hooks do
          run_callable(callable: definition.callable, type: :definition)
          definition.enhancements.each do |e|
            run_callable(callable: e, type: :enhancement)
          end
        end
      end

      value
    end

    def get(name)
      raise ArgumentError, "A store is required for #{definition.name}" unless store

      store.get(name, execution_context: execution_context)
    end
    alias [] get

    def method_missing(method_name, *args, &block)
      return super unless execution_context

      execution_context.send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name)
      return super unless execution_context

      execution_context.respond_to?(method_name, true)
    end

    private

    def run_callable(callable:, type:)
      @execution_type = type

      @value = if callable.arity.positive?
        instance_exec(self, &callable)
      else
        instance_eval(&callable)
      end
    end

    def maybe_set_store_context
      return yield unless store

      store.with_relative_schema(definition.schema) do
        yield
      end
    end

    def provide_schema_hooks
      return yield unless definition.schema

      @value = definition.schema.around_fixture_hook(self) do
        yield
        value
      end
    end

  end
end
