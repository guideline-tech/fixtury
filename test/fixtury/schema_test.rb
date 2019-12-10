# frozen_string_literal: true

require "test_helper"
require "fixtury/schema"

module Fixtury
  class SchemaTest < ::Test

    let(:schema) { ::Fixtury::Schema.new }

    def test_it_allows_fixtures_to_be_defined
      schema.define do
        fixture name: :foo do
          "foo"
        end

        fixture name: :bar do
          "bar"
        end
      end

      foo_def = schema.get_definition(name: :foo)
      bar_def = schema.get_definition(name: :bar)

      refute_nil foo_def
      refute_nil bar_def

      assert_equal "foo", foo_def.call
      assert_equal "bar", bar_def.call
    end

    def test_namespaces_can_be_used
      schema.define do
        namespace name: "bar" do
          fixture name: "baz" do
            "barbaz"
          end
        end
      end

      barbaz_def = schema.get_definition(name: "bar.baz")

      refute_nil barbaz_def

      assert_equal "barbaz", barbaz_def.call
    end

    def test_namespaces_can_be_used_twice
      schema.define do
        namespace name: "bar" do
          fixture name: "baz" do
            "barbaz"
          end
        end

        namespace name: "bar" do
          fixture name: "qux" do
            "barqux"
          end
        end
      end

      barbaz_def = schema.get_definition(name: "bar.baz")
      barqux_def = schema.get_definition(name: "bar.qux")

      refute_nil barbaz_def
      refute_nil barqux_def

      assert_equal "barbaz", barbaz_def.call
      assert_equal "barqux", barqux_def.call
    end

    def test_namespaces_can_be_nested
      schema.define do
        namespace name: "foo" do
          namespace name: "bar" do
            fixture name: "baz" do
              "foobarbaz"
            end
          end
        end
      end

      foobarbaz_def = schema.get_definition(name: "foo.bar.baz")
      refute_nil foobarbaz_def
      assert_equal "foobarbaz", foobarbaz_def.call
    end

    def test_schemas_can_be_reopened
      schema.define do
        fixture name: "foo" do
          "foo"
        end
      end

      schema.define do
        fixture name: "bar" do
          "bar"
        end
      end

      assert_equal 2, schema.definitions.size
    end

    def test_the_same_name_cannot_be_used_twice
      do_it = proc do
        schema.define do
          fixture name: "bar" do
            "bar"
          end
        end
      end

      do_it.call

      assert_equal 1, schema.definitions.size

      assert_raises Fixtury::Errors::FixtureAlreadyDefinedError do
        do_it.call
      end
    end

    def test_a_namespace_can_be_injected_via_define
      schema.define namespace: "ns1" do
        fixture name: "foo" do
          "ns1foo"
        end
      end

      assert_equal 1, schema.definitions.size

      ns_def = schema.get_definition(name: "ns1.foo")
      refute_nil ns_def
    end

  end
end
