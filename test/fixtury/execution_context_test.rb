# frozen_string_literal: true

require "test_helper"

module Fixtury
  class ExecutionContextTest < Test

    class ObserverExecutionContext

      attr_reader :events

      def initialize
        @events = []
      end

      def before_fixture(*args)
        @events << ["before", args]
      end

      def around_fixture(*args)
        @events << ["around", args]
        yield
      end

      def after_fixture(*args)
        @events << ["after", args]
      end

    end

    class NoInheritanceContext

    end

    class ModifyingExecutionContext

      def around_fixture(_dfn)
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

      fixture = dfn.call(execution_context: ctxt)
      expected = [
        ["before", [dfn]],
        ["around", [dfn]],
        ["after", [dfn, fixture]],
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

  end
end
