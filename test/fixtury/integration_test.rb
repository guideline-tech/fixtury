# frozen_string_literal: true

require "test_helper"
require "fixtury/cache"

module Fixtury
  class IntegrationTest < ::Test

    let :schema do
      ::Fixtury.define do
        fixture "earth" do
          "Earth"
        end

        namespace "countries" do
          fixture "usa" do
            "United States of America"
          end

          fixture "canada" do
            "Canada"
          end

          fixture "asu" do |db|
            db[:usa].reverse
          end
        end
      end
    end

    let :cache do
      ::Fixtury::Cache.new(schema: schema)
    end

    def test_a_fixtures_can_be_loaded
      assert_equal "United States of America", cache[:usa]
    end

  end
end
