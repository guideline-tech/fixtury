# frozen_string_literal: true

require "test_helper"
require "fixtury/locator"

module Fixtury
  class LocatorTest < Test

    class PassThroughBackend

      include ::Fixtury::LocatorBackend::Common

      def recognized_reference?(ref)
        ref.is_a?(String)
      end

      def recognized_value?(value)
        value.is_a?(String)
      end

      def load_recognized_reference(ref)
        "#{ref.sub("ref-", "")}-value"
      end

      def dump_recognized_value(value)
        "#{value.sub("-value", "")}-ref"
      end

    end

    def test_it_delegates_to_a_backend
      backend = mock
      backend.expects(:load).with("foo").returns("foo_value")
      backend.expects(:dump).with("bar").returns("bar_ref")

      loc = ::Fixtury::Locator.new(backend: backend)
      assert_equal "foo_value", loc.load("foo")
      assert_equal "bar_ref", loc.dump("name", "bar")
    end

    def test_it_provides_a_default_locator
      loc = ::Fixtury::Locator.new
      refute_nil loc

      assert_equal true, Fixtury::LocatorBackend::Memory === loc.backend
    end

    def test_structures_can_located
      backend = PassThroughBackend.new
      loc = ::Fixtury::Locator.new(backend: backend)

      assert_equal({ foo: "foo-value" }, loc.load({ foo: "ref-foo" }))
      assert_equal(["foo-value"], loc.load(["ref-foo"]))
    end

  end
end
