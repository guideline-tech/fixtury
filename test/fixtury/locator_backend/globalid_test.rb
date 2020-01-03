# frozen_string_literal: true

require "test_helper"
require "fixtury/locator_backend/globalid"

module Fixtury
  module LocatorBackend
    class GlobalIDTest < Test

      def test_it_locates_via_globalid
        ::GlobalID::Locator.expects(:locate).with("gid://foobar").returns("baz")
        instance = ::Fixtury::LocatorBackend::GlobalID.new
        value = instance.load("gid://foobar")
        assert_equal "baz", value
      end

      def test_it_dumps_via_globalid
        value_mock = mock
        global_id_mock = mock
        value_mock.expects(:to_global_id).returns(global_id_mock)
        global_id_mock.expects(:to_s).returns("foobar")

        instance = ::Fixtury::LocatorBackend::GlobalID.new
        value = instance.dump(value_mock)
        assert_equal "foobar", value
      end

    end
  end
end
