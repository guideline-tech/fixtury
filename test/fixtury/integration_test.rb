# frozen_string_literal: true

require "test_helper"

module Fixtury
  class IntegrationTest < ::Test

    let(:schema) { ::Fixtury.schema }
    let(:store) { ::Fixtury.store }

    def setup
      super
      load_default_fixtures
    end

    def test_a_fixtures_can_be_loaded
      assert_equal "Country", store["countries/country"]
    end

    def test_a_fixture_can_depend_on_another_fixture
      assert_equal "yrtnuoC", store["countries/reverse_country"]
    end

    def test_relative_matches_are_prioritized
      assert_equal "Country, Relative Earth", store["countries/relative_country"]
    end

    def test_absolute_matches_can_be_accessed
      assert_equal "Country, Earth", store["countries/absolute_country"]
    end

    def test_relatives_miss_if_they_dont_exist
      assert_raises Errors::SchemaNodeNotDefinedError do
        store["countries/towns/unknown_town"]
      end
    end

    def test_relatives_can_access_parent_fixtures
      assert_equal "Town, Relative Earth", store["countries/towns/relative_town"]
    end

    def test_absolutes_can_be_used_from_nesting
      assert_equal "Town, Earth", store["countries/towns/absolute_town"]
    end

  end
end
