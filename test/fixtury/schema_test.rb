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

      assert_raises Errors::AlreadyDefinedError do
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

      assert_raises Errors::AlreadyDefinedError do
        schema.define do
          namespace "foo" do
          end
        end
      end

      assert_raises Errors::AlreadyDefinedError do
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

    def test_schema_cannot_be_modified_once_frozen
      schema.define do
        fixture "foo" do
          "foo"
        end
      end

      schema.freeze!

      assert_raises Errors::SchemaFrozenError do
        schema.define{}
      end

      assert_raises Errors::SchemaFrozenError do
        schema.fixture("bar"){}
      end
    end

    def test_options_are_merged
      schema.define do
        namespace "thechild", foo: "foo"
      end

      schema.define do
        namespace "thechild", bar: "bar"
      end

      assert_equal({ foo: "foo", bar: "bar" }, schema.children["thechild"].options)
    end

    def test_conflicting_options_raise
      schema.define do
        namespace "thechild", foo: "foo"
      end

      # doesn't raise because the value is the same
      schema.define do
        namespace "thechild", foo: "foo"
      end

      # raises because a new value is encountered
      assert_raises Errors::OptionCollisionError do
        schema.define do
          namespace "thechild", foo: "bar"
        end
      end
    end

  end
end
