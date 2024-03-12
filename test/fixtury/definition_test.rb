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
      assert_equal "definition", dfn.schema_node_type
    end

    def test_callable_is_accessible
      block = proc { "foo" }
      dfn = ::Fixtury::Definition.new(name: "foo", &block)
      assert_equal block, dfn.callable
      assert_equal "foo", dfn.callable.call
    end

    def test_deps_option_can_be_a_string
      dfn = ::Fixtury::Definition.new(name: "foo", deps: "thing"){}
      deps = dfn.dependencies
      assert_equal 1, deps.size
      assert_equal(["thing"], deps.keys)
    end

    def test_deps_option_can_be_an_array_of_strings
      dfn = ::Fixtury::Definition.new(name: "foo", deps: %w[thing1 thing2]){}
      deps = dfn.dependencies
      assert_equal 2, deps.size
      assert_equal(["thing1", "thing2"], deps.keys)
      assert_equal "thing1", deps["thing1"].search
    end

    def test_deps_option_can_be_empty
      dfn = ::Fixtury::Definition.new(name: "foo"){}
      deps = dfn.dependencies
      assert_equal 0, deps.size
    end

    def test_deps_can_contain_a_pathname
      dfn = ::Fixtury::Definition.new(name: "foo", deps: "/foo/bar/baz"){}
      deps = dfn.dependencies
      assert_equal 1, deps.size
      assert_equal(["baz"], deps.keys)
      assert_equal "/foo/bar/baz", deps["baz"].search
    end

    def test_deps_can_be_an_array_of_arrays
      dfn = ::Fixtury::Definition.new(name: "foo", deps: [["foo", "bar"]]){}
      deps = dfn.dependencies
      assert_equal 1, deps.size
      assert_equal(["foo"], deps.keys)
      assert_equal "bar", deps["foo"].search
    end

    def test_deps_can_be_a_hash
      dfn = ::Fixtury::Definition.new(name: "foo", deps: { foo: "bar", biz: "baz" }){}
      deps = dfn.dependencies
      assert_equal 2, deps.size
      assert_equal(["foo", "biz"], deps.keys)
      assert_equal "bar", deps["foo"].search
      assert_equal "baz", deps["biz"].search
    end

    def test_deps_can_be_nested_single_item_hashes
      dfn = ::Fixtury::Definition.new(name: "foo", deps: [{ foo: "bar" }, { biz: "baz" }]){}
      deps = dfn.dependencies
      assert_equal 2, deps.size
      assert_equal(["foo", "biz"], deps.keys)
      assert_equal "bar", deps["foo"].search
      assert_equal "baz", deps["biz"].search
    end

    def test_deps_can_be_a_mix_of_all_the_things
      dfn = ::Fixtury::Definition.new(name: "foo", deps: [
        "thing1",
        :thing2,
        "/foo/bar/baz",
        ["foo", "bar"],
        { "biz" => "baz" },
      ]){}
      deps = dfn.dependencies
      assert_equal 5, deps.size
      assert_equal(["foo", "biz", "thing1", "thing2", "baz"].sort, deps.keys.sort)

      assert_equal "thing1", deps["thing1"].search
      assert_equal "thing2", deps["thing2"].search
      assert_equal "/foo/bar/baz", deps["baz"].search
      assert_equal "bar", deps["foo"].search
      assert_equal "baz", deps["biz"].search
    end

  end
end
