# frozen_string_literal: true

module Fixtury
  class Reference

    HOLDER_VALUE = "__BUILDING_FIXTURE__"

    def self.holder(name)
      new(name, HOLDER_VALUE)
    end

    def self.create(name, value)
      new(name, value)
    end

    attr_reader :name, :value, :created_at, :options

    def initialize(name, value, options = {})
      @name = name
      @value = value
      @created_at = Time.now.to_i
      @options = options
    end

    def holder?
      value == HOLDER_VALUE
    end

    def real?
      !holder?
    end

  end
end
