# frozen_string_literal: true

module Fixtury
  class Definition

    include ::Fixtury::SchemaNode
    extend ::Forwardable

    attr_reader :callable
    alias schema parent

    def_delegator :callable, :call

    def initialize(**opts, &block)
      super(**opts)
      @callable = block
    end

    def schema_node_type
      "dfn"
    end

    def acts_like_fixtury_definition?
      true
    end

  end
end
