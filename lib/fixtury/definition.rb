# frozen_string_literal: true

module Fixtury
  class Definition

    attr_reader :name
    attr_reader :set
    attr_reader :callable

    def initialize(name:, callable:)
      @name = name
      @callable = callable
    end

    def call(cache: nil)
      if callable.arity == 1
        raise ArgumentError, "A cache store must be provided if the definition expects it." unless cache

        instance_exec(cache, &callable)
      else
        instance_eval(&callable)
      end
    end

  end
end
