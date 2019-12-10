# frozen_string_literal: true

require "test_helper"
require "fixtury/locator"

module Fixtury
  class LocatorTest < Test

    def test_it_delegates_to_a_backend
      backend = mock
      backend.expects(:load).with("foo").returns("foo_value")
      backend.expects(:dump).with("bar").returns("bar_ref")

      loc = ::Fixtury::Locator.new(backend: backend)
      assert_equal "foo_value", loc.load("foo")
      assert_equal "bar_ref", loc.dump("bar")
    end

    def test_it_provides_a_default_locator
      loc = ::Fixtury::Locator.instance
      refute_nil loc

      assert_equal true, Fixtury::LocatorBackend::Memory === loc.backend
    end

  end
end
