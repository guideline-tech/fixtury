# frozen_string_literal: true

require "test_helper"
require "fixtury/definition"
require "fixtury/definition_executor"

module Fixtury
  class DefinitionExecutorTest < Test

    let(:definition) { ::Fixtury::Definition.new(name: "foo"){} }
    let(:erroring_definition) { ::Fixtury::Definition.new(name: "bar"){ raise "some runtime error" } }

    def test_definition_can_be_executed
      run_execution(definition)
    end

    def test_definition_execution_errors_are_wrapped_in_execution_error
      assert_raises Errors::DefinitionExecutionError do
        run_execution(erroring_definition)
      end
    end

    private

    def run_execution(dfn)
      ::Fixtury::DefinitionExecutor.new(definition: dfn).__call
    end

  end
end
