# frozen_string_literal: true

require "test_helper"
require "fixtury/locator"

module Fixtury
  class LocatorTest < Test

    class PassThroughBackend

      include ::Fixtury::LocatorBackend::Common

      def recognizable_key?(locator_key)
        locator_key.is_a?(String)
      end

      def recognizable_value?(value)
        value.is_a?(String)
      end

      def load_reference(locator_key)
        "#{locator_key.sub("ref-", "")}-value"
      end

      def dump_value(value)
        "#{value.sub("-value", "")}-ref"
      end

    end

    def test_it_delegates_to_a_backend
      backend = mock
      backend.expects(:load).with("foo").returns("foo_value")
      backend.expects(:dump).with("bar").returns("bar_ref")

      loc = ::Fixtury::Locator.new(backend: backend)
      assert_equal "foo_value", loc.load("foo")
      assert_equal "bar_ref", loc.dump("bar")
    end

    def test_it_provides_a_default_locator
      loc = ::Fixtury::Locator.new
      refute_nil loc

      assert_equal true, Fixtury::LocatorBackend::Memory === loc.backend
    end

    def test_structures_can_located
      loc = ::Fixtury::Locator.new(backend: PassThroughBackend.new)

      assert_equal({ foo: "foo-value" }, loc.load({ foo: "ref-foo" }))
      assert_equal(["foo-value"], loc.load(["ref-foo"]))
    end

  end
end
