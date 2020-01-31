# frozen_string_literal: true

module Fixtury
  class Reference

    HOLDER_VALUE = "__BUILDING_FIXTURE__"

    def self.holder(name)
      new(name, HOLDER_VALUE)
    end

    attr_reader :name, :value, :created_at

    def initialize(name, value)
      @name = name
      @value = value
      @created_at = Time.now.to_i
    end

    def holder?
      value == HOLDER_VALUE
    end

    def real?
      !holder?
    end

  end
end
