module Fixtury
  class Reference

    attr_reader :name, :value, :created_at

    def initialize(name, value)
      @name = name
      @value = value
      @created_at = Time.now.to_i
    end

  end
end
