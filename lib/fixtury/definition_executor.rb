# frozen_string_literal: true

require "benchmark"

module Fixtury
  # A container that manages the execution of a definition in the context of a store.
  class DefinitionExecutor

    class Output

      attr_accessor :value, :metadata

      def initialize
        @value = nil
        @metadata = {}
      end

    end

    attr_reader :output, :definition, :store

    def initialize(store: nil, definition:)
      @store = store
      @definition = definition
      @output = Output.new
    end

    def call
      run_definition
      output
    end

    private

    # If the callable has a positive arity we generate a DependencyStore
    # and yield it to the callable. Otherwise we just instance_eval the callable.
    # We wrap the actual execution of the definition with a hook for observation.
    def run_definition
      callable = definition.callable

      if callable.arity.positive?
        deps = build_dependency_store
        around_execution do
          instance_exec(deps, &callable)
        end
      else
        around_execution do
          instance_eval(&callable)
        end
      end
    rescue Errors::Base
      raise
    rescue => e
      raise Errors::DefinitionExecutionError.new(definition.pathname, e)
    end

    def around_execution(&block)
      measure_timing do
        @output.value = ::Fixtury.hooks.call(:execution, self, &block)
      end
    end

    def measure_timing(&block)
      @output.metadata[:duration] = Benchmark.realtime(&block)
    end

    def build_dependency_store
      DependencyStore.new(definition: definition, store: store)
    end

  end
end
