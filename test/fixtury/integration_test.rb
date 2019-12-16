# frozen_string_literal: true

require "test_helper"
require "fixtury/store"

module Fixtury
  class IntegrationTest < ::Test

    let :schema do
      ::Fixtury.define do
        fixture "earth" do
          "Earth"
        end

        namespace "countries" do
          fixture "country" do
            "Country"
          end

          fixture "reverse_country" do |db|
            db[:country].reverse
          end

          fixture "earth" do
            "Relative Earth"
          end

          fixture "relative_country" do |s|
            "#{s[:country]}, #{s[:earth]}"
          end

          fixture "absolute_country" do |s|
            "#{s[:country]}, #{s["/earth"]}"
          end

          namespace "towns" do
            fixture "unknown_town" do |s|
              "Town, #{s["./earth"]}"
            end

            fixture "relative_town" do |s|
              "Town, #{s["../earth"]}"
            end

            fixture "absolute_town" do |s|
              "Town, #{s["/earth"]}"
            end
          end
        end
      end
    end

    let :store do
      ::Fixtury::Store.new
    end

    def setup
      super
      schema
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
      assert_raises ::Fixtury::Errors::FixtureNotDefinedError do
        store["countries/towns/unknown_town"]
      end
    end

    def test_relatives_can_access_parent_fixtures
      $debug = true
      assert_equal "Town, Relative Earth", store["countries/towns/relative_town"]
    ensure
      $debug = false
    end

    def test_absolutes_can_be_used_from_nesting
      assert_equal "Town, Earth", store["countries/towns/absolute_town"]
    end

  end
end
