# frozen_string_literal: true

require "test_helper"
require "fixtury/test_hooks"

module Fixtury
  class TestHooksTest < ::Test

    def setup
      super
      ::Fixtury.define do
        namespace "global" do
          fixture("foo") { "foo" }
          fixture("reverse_foo") { |s| s["foo"].reverse }
          fixture("bar") { "bar" }
        end
      end
    end

    def test_dependencies_are_recorded
      klass = Class.new do
        include ::Fixtury::TestHooks

        fixtury "global/foo", as: false
        fixtury "global/bar", as: "barrr"
        fixtury "global/baz"
      end

      assert_equal(
        %w[/global/foo /global/bar /global/baz],
        klass.fixtury_dependencies.to_a
      )
    end

    def test_accessors_are_created
      klass = Class.new do
        include ::Fixtury::TestHooks

        fixtury "/global/foo", as: false
        fixtury "/global/bar", as: "barrr"
        fixtury "/global/baz"
      end

      instance = klass.new
      assert_equal false, instance.respond_to?(:foo)
      assert_equal false, instance.respond_to?(:bar)
      assert_equal true, instance.respond_to?(:barrr)
      assert_equal true, instance.respond_to?(:baz)

      assert_equal "bar", instance.barrr
      assert_raises Fixtury::Errors::SchemaNodeNotDefinedError do
        instance.baz
      end
    end

  end
end
