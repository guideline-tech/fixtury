# frozen_string_literal: true

require "test_helper"

module Fixtury
  class DefinitionExecutorTest < Test

    def test_definition_execution_errors_are_wrapped_in_execution_error
      dfn = ::Fixtury::Definition.new(name: "bar"){ raise "some runtime error" }
      executor = ::Fixtury::DefinitionExecutor.new(definition: dfn)
      begin
        executor.call
        refute true, "Should have raised"
      rescue Errors::DefinitionExecutionError => e
        assert_equal e.backtrace, e.original_error.backtrace
      end
    end

    def test_definition_does_not_yield_anything_if_arity_is_zero
      dfn = ::Fixtury::Definition.new(name: "foo"){}
      executor = ::Fixtury::DefinitionExecutor.new(definition: dfn)
      executor.expects(:get).never
      executor.call
    end

    def test_definition_yields_a_dependency_store_if_arity_is_positive
      dfn = ::Fixtury::Definition.new(name: "foo") { |s| s.get("thing") }
      executor = ::Fixtury::DefinitionExecutor.new(definition: dfn)
      Fixtury::DependencyStore.any_instance.expects(:get).with("thing").once.returns("foobar")
      executor.call
    end

    def test_return_value_is_an_output_object
      dfn = ::Fixtury::Definition.new(name: "foo") { |s| s.get("thing") }
      executor = ::Fixtury::DefinitionExecutor.new(definition: dfn)
      Fixtury::DependencyStore.any_instance.expects(:get).with("thing").once.returns("foobar")
      output = executor.call
      assert_instance_of ::Fixtury::DefinitionExecutor::Output, output
      assert_equal "foobar", output.value
      assert output.metadata.key?(:duration)
    end

  end
end
