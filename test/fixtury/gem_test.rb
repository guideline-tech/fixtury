# frozen_string_literal: true

require "test_helper"
require "support/db"

module Fixtury
  class GemTest < Test

    def test_that_it_has_a_version_number
      refute_nil ::Fixtury::VERSION
    end

    def test_the_fake_db_works
      ::Support::Db.clear
      assert_nil ::Support::Db.read("foo")

      ::Support::Db.write("foo", "bar")
      assert_equal "bar", ::Support::Db.read("foo")
      assert_equal "bar", ::Support::Db.del("foo")

      assert_nil ::Support::Db.read("foo")

      assert_raises do
        ::Support::Db.read!("foo")
      end
    end

  end
end
