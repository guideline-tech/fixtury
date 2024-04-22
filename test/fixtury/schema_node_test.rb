# frozen_string_literal: true

require "test_helper"

module Fixtury
  class SchemaNodeTest < ::Test

    class Node
      include ::Fixtury::SchemaNode
    end

    def test__isolation_key__inherits_from_parent_first
      parent = Node.new(name: "foobar")
      parent.apply_options!(isolate: true)
      child = Node.new(parent: parent, name: "bar")
      assert_equal "/foobar", child.isolation_key
    end

    def test__isolation_key__defaults_to_name
      parent = Node.new(name: "foobar")
      child = Node.new(parent: parent, name: "bar")
      assert_equal "/foobar/bar", child.isolation_key
    end

    def test__isolation_key__if_name_blank_return_nil
      node = Node.new(name: "")
      assert_nil node.isolation_key
    end

    def test__schema_node_type__should_default_to_the_demodularized_class_name
      node = Node.new(name: "foo")
      assert_equal "node", node.schema_node_type
    end

    def test__acts_like__integration
      node = Node.new(name: "foo")
      assert node.acts_like?(:fixtury_schema_node)
      assert node.acts_like_fixtury_schema_node?
    end

    def test__first_ancestor__returns_top_node
      grandparent = Node.new(name: "grandparent")
      parent = Node.new(parent: grandparent, name: "parent")
      child = Node.new(parent: parent, name: "child")

      assert_equal grandparent, child.first_ancestor
      assert_equal grandparent, parent.first_ancestor
      assert_equal grandparent, grandparent.first_ancestor
    end
    def test__get__returns_nil_for_miss
      s = build_complex_schema
      assert_nil s[:root].get("missing")
    end

    def test__get__accesses_items_by_simple_name
      s = build_complex_schema
      assert_equal s[:child1], s[:root].get("child1")
      assert_equal s[:ns1_child1], s[:ns1].get("child1")
      assert_equal s[:ns1_child1], s[:root].get("ns1/child1")
      assert_equal s[:ns2_child1], s[:ns2].get("child1")
    end

    def test__get__accesses_absolute_items
      s = build_complex_schema
      assert_equal s[:child1], s[:root].get("/child1")
      assert_equal s[:child1], s[:ns1].get("/child1")
      assert_equal s[:child1], s[:ns2].get("/child1")
    end

    def test__get__accesses_relative_paths
      s = build_complex_schema

      assert_equal s[:child1], s[:root].get("child1")
      assert_equal s[:child1], s[:ns1].get("../child1")
      assert_equal s[:child1], s[:ns2].get("../../child1")

      assert_equal s[:ns1_child1], s[:root].get("ns1/child1")
      assert_equal s[:ns2_child1], s[:root].get("ns1/ns2/child1")
      assert_equal s[:ns2_child1], s[:ns1].get("ns2/child1")

      assert_equal s[:root], s[:ns1].get("..")
      assert_equal s[:ns1], s[:ns1].get(".")
      assert_equal s[:ns2], s[:ns1].get("./../ns1/ns2")
    end

    def test_options_are_merged
      node = Node.new(name: "foo", optiona: "optiona")
      assert_equal({ optiona: "optiona" }, node.options)

      node.apply_options!(optionb: "optionb")
      assert_equal({ optiona: "optiona", optionb: "optionb" }, node.options)
    end

    def test_conflicting_options_raise
      node = Node.new(name: "foo", optiona: "optiona")
      assert_equal({ optiona: "optiona" }, node.options)

      # same value, so it's fine
      node.apply_options!(optiona: "optiona")

      # raises because a new value is encountered
      assert_raises Errors::OptionCollisionError do
        node.apply_options!(optiona: "new_value")
      end
    end

    def test__inspect__doesnt_represent_nested_structure
      s = build_complex_schema
      assert_equal "#{Node.name}(pathname: \"\/\", children: 2)", s[:root].inspect
      assert_equal "#{Node.name}(pathname: \"\/ns1\/ns2\", children: 1)", s[:ns2].inspect
    end


    def test_structure_is_represented
      node = Node.new(name: "foo"){}
      assert_equal "node:foo", node.structure

      node = Node.new(name: "foo", optiona: "optiona", optionb: "optionb"){}
      assert_equal "node:foo(optiona: \"optiona\", optionb: \"optionb\")", node.structure

      node = Node.new(name: "foo", optiona: "optiona", optionb: "optionb", isolate: "/foo/bar/baz"){}
      assert_equal "node:foo[/foo/bar/baz](optiona: \"optiona\", optionb: \"optionb\")", node.structure
    end

    private

    def build_complex_schema
      root = Node.new(name: "")
      child1 = Node.new(parent: root, name: "child1")
      ns1 = Node.new(parent: root, name: "ns1")
      ns1_child1 = Node.new(parent: ns1, name: "child1")
      ns_child2 = Node.new(parent: ns1, name: "child2")
      ns2 = Node.new(parent: ns1, name: "ns2")
      ns2_child1 = Node.new(parent: ns2, name: "child1")

      # root.structure #=>
      # root_node:
      #   node:child1
      #   node:ns1
      #     node:child1
      #     node:child2
      #     node:ns2
      #       node:child1

      {
        root: root,
        child1: child1,
        ns1: ns1,
        ns1_child1: ns1_child1,
        ns1_child2: ns_child2,
        ns2: ns2,
        ns2_child1: ns2_child1,
      }
    end

  end
end
