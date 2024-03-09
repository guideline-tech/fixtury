# frozen_string_literal: true

require "test_helper"

module Fixtury
  class DefinitionExecutorTest < Test

    def test_definition_execution_errors_are_wrapped_in_execution_error
      dfn = ::Fixtury::Definition.new(name: "bar"){ raise "some runtime error" }
      executor = ::Fixtury::DefinitionExecutor.new(definition: dfn)
      assert_raises Errors::DefinitionExecutionError do
        executor.call
      end
    end

    def test_definition_does_not_yield_if_arity_is_zero
      dfn = ::Fixtury::Definition.new(name: "foo"){}
      executor = ::Fixtury::DefinitionExecutor.new(definition: dfn)
      executor.expects(:get).never
      executor.call
    end

    def test_definition_yields_itself_if_arity_on_the_block
      dfn = ::Fixtury::Definition.new(name: "foo") { |s| s.get("thing") }
      executor = ::Fixtury::DefinitionExecutor.new(definition: dfn)
      executor.expects(:get).with("thing").once.returns("foobar")
      executor.call
    end

  end
end
