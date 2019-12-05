# frozen_string_literal: true

module Fixtury
  class Namespace

    attr_reader :name
    attr_reader :schema
    attr_reader :block

    def initialize(schema, name, &block)
      @schema = schema
      @name = name
      @block = block
    end

    alias to_s name

    def run(store)
      if block.arity == 1
        schema.instance_exec(store, &block)
      else
        schema.instance_exec(&block)
      end
    end

  end
end
