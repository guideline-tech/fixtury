# frozen_string_literal: true

module Fixtury
  class Definition

    attr_reader :name
    attr_reader :namespace

    attr_reader :callable
    attr_reader :enhancements

    def initialize(namespace: nil, name:, &block)
      @name = name
      @namespace = namespace
      @callable = block
      @enhancements = []
    end

    def enhance(&block)
      @enhancements << block
    end

    def call(cache: nil)
      value = run_callable(cache: cache, callable: callable, value: nil)
      enhancements.each do |e|
        run_callable(cache: cache, callable: e, value: value)
      end
      value
    end

    protected

    def run_callable(cache:, callable:, value:)
      args = []
      args << value unless value.nil?
      if callable.arity > args.length
        raise ArgumentError, "A cache store must be provided if the definition expects it." unless cache

        args << cache
      end
      if args.length.positive?
        instance_exec(*args, &callable)
      else
        instance_eval(&callable)
      end
    end

  end
end
