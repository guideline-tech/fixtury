# frozen_string_literal: true

require "test_helper"
require "fixtury/namespace"

module Fixtury
  class NamespaceTest < ::Test

    let(:ns) { ::Fixtury::Namespace.new(namespace: nil, name: "test") }

    def test_it_allows_fixtures_to_be_defined
      ns.define do
        fixture :foo do
          "foo"
        end

        fixture :bar do
          "bar"
        end
      end

      foo_def = ns.get_definition(name: :foo)
      bar_def = ns.get_definition(name: :bar)

      refute_nil foo_def
      refute_nil bar_def

      assert_equal "foo", foo_def.call
      assert_equal "bar", bar_def.call
    end

    def test_namespaces_can_be_used
      ns.define do
        namespace name: "bar" do
          fixture "baz" do
            "barbaz"
          end
        end
      end

      barbaz_def = ns.get_definition(name: "bar.baz")

      refute_nil barbaz_def

      assert_equal "barbaz", barbaz_def.call
    end

    def test_namespaces_can_be_used_twice
      ns.define do
        namespace name: "bar" do
          fixture "baz" do
            "barbaz"
          end
        end

        namespace name: "bar" do
          fixture "qux" do
            "barqux"
          end
        end
      end

      barbaz_def = ns.get_definition(name: "bar.baz")
      barqux_def = ns.get_definition(name: "bar.qux")

      refute_nil barbaz_def
      refute_nil barqux_def

      assert_equal "barbaz", barbaz_def.call
      assert_equal "barqux", barqux_def.call
    end

    def test_namespaces_can_be_nested
      ns.define do
        namespace name: "foo" do
          namespace name: "bar" do
            fixture "baz" do
              "foobarbaz"
            end
          end
        end
      end

      foobarbaz_def = ns.get_definition(name: "foo.bar.baz")
      refute_nil foobarbaz_def
      assert_equal "foobarbaz", foobarbaz_def.call
    end

    def test_schemas_can_be_reopened
      ns.define do
        fixture "foo" do
          "foo"
        end
      end

      ns.define do
        fixture "bar" do
          "bar"
        end
      end

      assert_equal 2, ns.definitions.size
    end

    def test_the_same_name_cannot_be_used_twice
      do_it = proc do
        ns.define do
          fixture "bar" do
            "bar"
          end
        end
      end

      do_it.call

      assert_equal 1, ns.definitions.size

      assert_raises Fixtury::Errors::FixtureAlreadyDefinedError do
        do_it.call
      end
    end

  end
end
