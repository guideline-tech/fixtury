# frozen_string_literal: true

module Fixtury
  class Reference

    HOLDER_KEY = "__BUILDING_FIXTURE__"

    def self.holder(name)
      new(name, HOLDER_KEY)
    end

    attr_reader :name, :locator_key, :created_at, :options

    def initialize(name, locator_key, options = {})
      @name = name
      @locator_key = locator_key
      @created_at = Time.now.to_i
      @options = options
    end

    def holder?
      locator_key == HOLDER_KEY
    end

    def real?
      !holder?
    end

  end
end
