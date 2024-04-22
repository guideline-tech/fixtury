# frozen_string_literal: true

require "test_helper"
require "fixtury/minitest_hooks"

module Fixtury
  class MinitestHooksTest < ::Test

    uses_db

    def setup
      super
      ::Fixtury.define do
        fixture("foo"){ "root foo" }
        namespace "global" do
          fixture("foo") { "foo" }
          fixture("reverse_foo") { |s| s["foo"].reverse }
          fixture("bar") { "bar" }
        end
      end
    end

    def test_dependencies_are_recorded
      klass = Class.new do
        prepend ::Fixtury::MinitestHooks

        fixtury "global/foo", as: false
        fixtury "global/bar", as: "barrr"
      end

      assert_equal(
        %w[/global/foo /global/bar],
        klass.fixtury_dependencies.to_a
      )
    end

    def test_accessors_are_created
      klass = Class.new do
        prepend ::Fixtury::MinitestHooks

        fixtury "/global/foo", as: false
        fixtury "/global/bar", as: "barrr"
      end

      instance = klass.new
      assert_equal false, instance.respond_to?(:foo)
      assert_equal false, instance.respond_to?(:bar)
      assert_equal true, instance.respond_to?(:barrr)

      assert_equal "bar", instance.barrr
    end

    def test_references_are_built_relative_to_root
      klass = Class.new do
        prepend ::Fixtury::MinitestHooks

        fixtury "/foo", as: false
        fixtury "/global/bar", as: "barrr"
      end
    end

    def test_references_to_unrecognized_fixtures_blow_up
      assert_raises Fixtury::Errors::SchemaNodeNotDefinedError do
        Class.new do
          prepend ::Fixtury::MinitestHooks

          fixtury "/doesnt/exist"
        end
      end
    end

    def test_it_hooks_into_minitest_lifecycle
      $loaded_fixtures = nil

      ::Fixtury.stubs(:log)
      ::Fixtury.expects(:log).with("preloading \"/global/foo\"", name: "test", level: ::Fixtury::LOG_LEVEL_INFO)
      ::Fixtury.expects(:log).with("preloading \"/global/bar\"", name: "test", level: ::Fixtury::LOG_LEVEL_INFO)

      klass = Class.new(::Minitest::Test) do
        prepend ::Fixtury::MinitestHooks

        fixtury "/global/foo", as: false
        fixtury "/global/bar", as: "barrr"

        def test_it
          $loaded_fixtures = ::Fixtury.store.references
        end
      end

      assert_equal %w[/global/foo /global/bar], klass.fixtury_dependencies.to_a
      Minitest.run_one_method klass, :test_it

      assert_equal(%w[/global/bar /global/foo], $loaded_fixtures.keys.sort)
    ensure
      $loaded_fixtures = nil
    end

  end
end
