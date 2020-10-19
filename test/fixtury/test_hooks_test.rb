# frozen_string_literal: true

require "test_helper"
require "fixtury/test_hooks"

module Fixtury
  class TestHooksTest < ::Test

    class SomeTestClass

      include ::Fixtury::TestHooks

      # This is needed because we reset the global fixtures every time.
      # Normally these calls would occur directly on the class
      def self.bootstrap
        fixtury "global/foo", accessor: false
        fixtury "global/bar", accessor: "barrr"
        fixtury "global/baz"

        fixtury "qux", accessor: false do |_store|
          "qux"
        end

        fixtury "bux" do
          "bux"
        end
      end

      def fixtury_store
        @fixtury_store ||= ::Fixtury::Store.new(schema: ::Fixtury.schema)
      end

    end

    let(:schema) do
      ::Fixtury.define do
        namespace "global" do
          fixture "foo" do
            "foo"
          end

          fixture "reverse_foo" do |store|
            store["foo"].reverse
          end

          fixture "bar" do
            "bar"
          end
        end
      end
    end

    def setup
      super
      schema
      SomeTestClass.bootstrap
    end

    def test_dependencies_are_recorded
      assert_equal(
        %w[global/foo global/bar global/baz fixtury/test_hooks_test/some_test_class/qux fixtury/test_hooks_test/some_test_class/bux],
        SomeTestClass.fixtury_dependencies.to_a
      )
    end

    def test_accessors_are_created
      instance = SomeTestClass.new

      assert_equal false, instance.respond_to?(:foo)
      assert_equal false, instance.respond_to?(:qux)
      assert_equal false, instance.respond_to?(:bar)
      assert_equal true, instance.respond_to?(:barrr)
      assert_equal true, instance.respond_to?(:baz)
      assert_equal true, instance.respond_to?(:bux)
    end

    def test_fixtures_are_accessible
      instance = SomeTestClass.new

      assert_equal "foo", instance.fixtury("global/foo")
      assert_equal "bar", instance.barrr

      assert_raises Fixtury::Errors::FixtureNotDefinedError do
        instance.baz
      end

      assert_equal "qux", instance.fixtury("qux")
      assert_equal "bux", instance.fixtury("bux")
      assert_equal "bux", instance.bux
    end

  end
end
