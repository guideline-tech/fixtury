# frozen_string_literal: true

require "test_helper"
require "fixtury/cache"

module Fixtury
  class IntegrationTest < ::Test

    let :schema do
      ::Fixtury::Schema.define do
        fixture name: "earth" do
          "Earth"
        end

        namespace name: "countries" do
          fixture name: "usa" do
            "United States of America"
          end

          fixture name: "canada" do
            "Canada"
          end

          fixture name: "asu" do |db|
            db[:usa].reverse
          end
        end
      end
    end

    let :cache do
      ::Fixtury::Cache.new(schema: schema)
    end

    def test_a_fixtures_can_be_loaded
      assert_eq "United States of America", cache[:usa]
    end

  end
end
