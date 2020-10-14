# frozen_string_literal: true

require "test_helper"

module Fixtury
  class ExecutionContextTest < Test

    class ObserverExecutionContext

      attr_reader :events

      def initialize
        @events = []
      end

      def before_fixture(exec)
        @events << ["before", exec.definition, exec.value, exec.execution_type]
      end

      def around_fixture(exec)
        @events << ["around", exec.definition, exec.value, exec.execution_type]
        yield
      end

      def after_fixture(exec)
        @events << ["after", exec.definition, exec.value, exec.execution_type]
      end

      def around_fixture_get(exec)
        @events << ["around_fixture_get", exec.definition, exec.value, exec.execution_type]
        yield
      end

    end

    class NoInheritanceContext

    end

    class ModifyingExecutionContext

      def around_fixture(_exec)
        value = yield
        value * 2
      end

    end

    def dfn
      @dfn ||= ::Fixtury::Definition.new(name: "foo") { "foo" }
    end

    def test_execution_context_is_utilized_by_definitions
      ctxt = ObserverExecutionContext.new
      assert_equal [], ctxt.events

      fixture_value = dfn.call(execution_context: ctxt)

      expected = [
        ["before", dfn, nil, :definition],
        ["around", dfn, nil, :definition],
        ["after", dfn, fixture_value, :definition],
      ]
      assert_equal(expected, ctxt.events)
    end

    def test_execution_contex_does_not_need_to_respond_to_hooks
      ctxt = NoInheritanceContext.new
      assert_equal "foo", dfn.call(execution_context: ctxt)
    end

    def test_execution_context_can_modify_the_fixture
      ctxt = ModifyingExecutionContext.new
      value = dfn.call(execution_context: ctxt)
      assert_equal "foofoo", value
    end

    def test_execution_can_observe_items_retrieved_within_the_definition
      schema = ::Fixtury::Schema.new(parent: nil, name: "test")
      schema.define do
        fixture "foo" do
          "foo"
        end

        fixture "bar" do |x|
          x["foo"].reverse
        end
      end

      ctxt = ObserverExecutionContext.new
      store = ::Fixtury::Store.new(execution_context: ctxt, schema: schema)
      dfn = schema.get_definition!("bar")

      store["bar"]

      event = ctxt.events.detect { |e| e[0] == "around_fixture_get" }

      assert_equal(["around_fixture_get", dfn, nil, :definition], event)
    end

  end
end
