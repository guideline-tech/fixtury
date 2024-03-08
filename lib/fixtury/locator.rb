# frozen_string_literal: true

require "fixtury/locator_backend/memory"

module Fixtury
  # Locator is a class that is responsible for recognizing, loading, and dumping references.
  # It is a simple wrapper around a backend that is responsible for the actual work.
  # The backend is expected to implement the following methods: recognized_reference?, recognized_value?, load_recognized_reference, dump_recognized_value.
  class Locator

    attr_reader :backend

    def initialize(backend: ::Fixtury::LocatorBackend::Memory.new)
      @backend = backend
    end

    def recognize?(locator_key)
      raise ArgumentError, "Unable to recognize a nil locator value" if locator_key.nil?

      backend.recognized_reference?(locator_key)
    end

    def load(locator_key)
      raise ArgumentError, "Unable to load a nil locator value" if locator_key.nil?

      backend.load(locator_key)
    end

    def dump(name, stored_value)
      raise ArgumentError, "Unable to dump a nil value for ref: #{name}" if stored_value.nil?

      locator_key = backend.dump(stored_value)
      raise ArgumentError, "Dump resulted in a nil locator value: #{name}" if locator_key.nil?

      locator_key
    end

  end
end
