# frozen_string_literal: true

require "fixtury/definition_executor"

module Fixtury
  class Definition

    attr_reader :name
    attr_reader :schema

    attr_reader :callable
    attr_reader :enhancements

    def initialize(schema: nil, name:, &block)
      @name = name
      @schema = schema
      @callable = block
      @enhancements = []
    end

    def enhance(&block)
      @enhancements << block
    end

    def enhanced?
      @enhancements.any?
    end

    def info
      {
        name: name,
        loc: location_from_callable(callable),
        enhancements: enhancements.map { |e| location_from_callable(e) },
      }
    end

    def call(store: nil, execution_context: nil)
      executor = ::Fixtury::DefinitionExecutor.new(store: store, definition: self, execution_context: execution_context)
      executor.__call
    end

    def location_from_callable(callable)
      return nil unless callable.respond_to?(:source_location)

      callable.source_location.join(":")
    end

  end
end
