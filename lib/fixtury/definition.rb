# frozen_string_literal: true

module Fixtury
  class Definition

    attr_reader :name
    attr_reader :schema
    alias parent schema
    attr_reader :options

    attr_reader :callable

    def initialize(name:, schema: nil, options: {}, &block)
      @name = name
      @schema = schema
      @callable = block
      @options = options
    end

    def info
      {
        name: name,
        loc: location_from_callable(callable),
      }
    end

    def call(store: nil)
      executor = ::Fixtury::DefinitionExecutor.new(store: store, definition: self)
      executor.__call
    end

    def location_from_callable(callable)
      return nil unless callable.respond_to?(:source_location)

      callable.source_location.join(":")
    end

  end
end
