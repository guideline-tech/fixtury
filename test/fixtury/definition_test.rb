# frozen_string_literal: true

require "test_helper"
require "fixtury/definition"

module Fixtury
  class DefinitionTest < Test

    def test_it_can_be_instantiated
      ::Fixtury::Definition.new(name: "foo"){}
    end

    def test_it_has_the_right_schema_node_type
      dfn = ::Fixtury::Definition.new(name: "foo"){}
      assert_equal "dfn", dfn.schema_node_type
    end

    def test_callable_is_accessible
      block = proc { "foo" }
      dfn = ::Fixtury::Definition.new(name: "foo", &block)
      assert_equal block, dfn.callable
    end

    def test_structure_is_represented
      dfn = ::Fixtury::Definition.new(name: "foo"){}
      assert_equal "dfn:foo", dfn.structure

      dfn = ::Fixtury::Definition.new(name: "foo", optiona: "optiona", optionb: "optionb"){}
      assert_equal "dfn:foo({:optiona=>\"optiona\", :optionb=>\"optionb\"})", dfn.structure
    end

  end
end
