# frozen_string_literal: true

require "test_helper"
require "fixtury/schema"

module Fixtury
  class SchemaTest < ::Test

    let(:schema) { ::Fixtury::Schema.new(parent: nil, name: "test") }
    let(:other_schema) { ::Fixtury::Schema.new(parent: nil, name: "test2") }

    def test_it_allows_fixtures_to_be_defined
      schema.define do
        fixture :foo do
          "foo"
        end

        fixture :bar do
          "bar"
        end
      end

      foo_def = schema.get_definition!(:foo)
      bar_def = schema.get_definition!(:bar)

      assert_equal "foo", foo_def.call
      assert_equal "bar", bar_def.call
    end

    def test_schemas_can_be_used
      schema.define do
        namespace "bar" do
          fixture "baz" do
            "barbaz"
          end
        end
      end

      barbaz_def = schema.get_definition!("bar/baz")

      assert_equal "barbaz", barbaz_def.call
    end

    def test_schemas_can_be_used_twice
      schema.define do
        namespace "bar" do
          fixture "baz" do
            "barbaz"
          end
        end

        namespace "bar" do
          fixture "qux" do
            "barqux"
          end
        end
      end

      barbaz_def = schema.get_definition!("bar/baz")
      barqux_def = schema.get_definition!("bar/qux")

      assert_equal "barbaz", barbaz_def.call
      assert_equal "barqux", barqux_def.call
    end

    def test_schemas_can_be_nested
      schema.define do
        namespace "foo" do
          namespace "bar" do
            fixture "baz" do
              "foobarbaz"
            end
          end
        end
      end

      foobarbaz_def = schema.get_definition!("foo/bar/baz")
      assert_equal "foobarbaz", foobarbaz_def.call
    end

    def test_schemas_can_be_reopened
      schema.define do
        fixture "foo" do
          "foo"
        end
      end

      schema.define do
        fixture "bar" do
          "bar"
        end
      end

      assert_equal 2, schema.definitions.size
    end

    def test_the_same_name_cannot_be_used_twice
      do_it = proc do
        schema.define do
          fixture "bar" do
            "bar"
          end
        end
      end

      do_it.call

      assert_equal 1, schema.definitions.size

      assert_raises Fixtury::Errors::AlreadyDefinedError do
        do_it.call
      end
    end

    def test_a_namespace_and_fixture_cannot_use_the_same_name
      schema.define do
        fixture "foo" do
          "foo"
        end

        namespace "bar" do
          fixture "baz" do
          end
        end
      end

      assert_raises Fixtury::Errors::AlreadyDefinedError do
        schema.define do
          namespace "foo" do
          end
        end
      end

      assert_raises Fixtury::Errors::AlreadyDefinedError do
        schema.define do
          fixture "bar" do
          end
        end
      end
    end

    def test_a_fixture_with_the_same_name_can_be_defined_within_a_namespace
      schema.define do
        fixture "foo" do
          "foo"
        end

        namespace "bar" do
          fixture "foo" do
            "bar/foo"
          end
        end
      end

      foo_def = schema.get_definition!("foo")
      barfoo_def = schema.get_definition!("bar/foo")

      assert_equal "foo", foo_def.call
      assert_equal "bar/foo", barfoo_def.call
    end

    def test_other_schemas_can_be_merged
      schema.define do
        namespace "foo" do
          fixture "nesteda" do
            "foo/nesteda"
          end
        end

        fixture "topa" do
          "topa"
        end
      end

      other_schema.define do
        namespace "foo" do
          fixture "nestedb" do
            "foo/nestedb"
          end
        end

        fixture "topb" do
          "topb"
        end
      end

      o = other_schema

      schema.define do
        merge o
      end

      assert_equal 1, schema.children.size
      assert_equal 2, schema.definitions.size

      assert_equal 1, other_schema.children.size
      assert_equal 1, other_schema.definitions.size

      original_topa_def = schema.get_definition!("topa")
      original_topb_def = other_schema.get_definition!("topb")
      merged_topb_def = schema.get_definition!("topb")

      original_nesteda_def = schema.get_definition!("foo/nesteda")
      original_nestedb_def = other_schema.get_definition!("foo/nestedb")
      merged_nestedb_def = schema.get_definition!("foo/nestedb")

      assert_equal "topa", original_topa_def.call
      assert_equal "topb", original_topb_def.call
      assert_equal "topb", merged_topb_def.call

      assert_equal "foo/nesteda", original_nesteda_def.call
      assert_equal "foo/nestedb", original_nestedb_def.call
      assert_equal "foo/nestedb", merged_nestedb_def.call

      refute_equal original_topb_def.object_id, merged_topb_def.object_id
      refute_equal original_nestedb_def.object_id, merged_nestedb_def.object_id
    end

    def test_fixtures_can_be_enhanced
      o = other_schema
      o.define do
        fixture "foo" do
          "foo"
        end
      end

      schema.define do
        merge o

        enhance "foo" do |e|
          e.value * 2
        end
      end

      foofoodef = schema.get_definition!("foo")

      assert_equal true, foofoodef.enhanced?
      assert_equal "foofoo", foofoodef.call

      foodef = o.get_definition!("foo")
      assert_equal false, foodef.enhanced?
      assert_equal "foo", foodef.call
    end

    def test_schema_cannot_be_modified_once_frozen
      schema.define do
        fixture "foo" do
          "foo"
        end
      end

      schema.freeze!

      assert_raises ::Fixtury::Errors::SchemaFrozenError do
        schema.define{}
      end

      assert_raises ::Fixtury::Errors::SchemaFrozenError do
        schema.fixture("bar"){}
      end

      assert_raises ::Fixtury::Errors::SchemaFrozenError do
        schema.enhance("foo"){}
      end
    end

  end
end
