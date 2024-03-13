# frozen_string_literal: true

require "test_helper"
require "fixtury/locator_backend/memory"

module Fixtury
  module LocatorBackend
    class MemoryTest < Test

      def test_it_creates_refs_from_the_object_id
        loc = ::Fixtury::LocatorBackend::Memory.new

        a = +"foo"
        b = +"foo"

        assert_equal a, b
        refute_equal a.object_id, b.object_id

        a_ref = loc.dump(a)
        b_ref = loc.dump(b)

        assert_equal "fixtury-oid-#{Process.pid}-#{a.object_id}", a_ref
        assert_equal "fixtury-oid-#{Process.pid}-#{b.object_id}", b_ref

        a2 = loc.load(a_ref)
        assert_equal a2.object_id, a.object_id
        assert_equal a2, a
      end

      def test_it_fetches_from_objectspace
        loc = ::Fixtury::LocatorBackend::Memory.new
        a = +"foo"
        assert_equal a, loc.load("fixtury-oid-#{Process.pid}-#{a.object_id}")
      end

    end
  end
end
