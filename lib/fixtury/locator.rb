# frozen_string_literal: true

require "fixtury/locator_backend/memory"

module Fixtury
  # Locator is responsible for recognizing, loading, and dumping references.
  # It is a simple wrapper around a backend that is responsible for the actual work.
  # The backend is expected to implement the following methods: recognizable_key?, recognized_value?, load_recognized_reference, dump_recognized_value.
  class Locator

    attr_reader :backend

    def initialize(backend: ::Fixtury::LocatorBackend::Memory.new)
      @backend = backend
    end

    def inspect
      "#{self.class}(backend: #{backend.class})"
    end

    # Determine if the provided locator_key is a valid form recognized by the backend.
    #
    # @param locator_key [Object] the locator key to check
    # @return [Boolean] true if the locator key is recognizable by the backend
    # @raise [ArgumentError] if the locator key is nil
    def recognizable_key?(locator_key)
      raise ArgumentError, "Unable to recognize a nil locator value" if locator_key.nil?

      backend.recognizable_key?(locator_key)
    end

    # Load the value associated with the provided locator key.
    #
    # @param locator_key [Object] the locator key to load
    # @return [Object] the loaded value
    # @raise [ArgumentError] if the locator key is nil
    def load(locator_key)
      raise ArgumentError, "Unable to load a nil locator value" if locator_key.nil?

      backend.load(locator_key)
    end

    # Provide the value to the backend to generate a locator key.
    #
    # @param stored_value [Object] the value to dump
    # @param context [String] a string to include in the error message if the value is nil
    # @return [Object] the locator key
    # @raise [ArgumentError] if the value is nil
    # @raise [ArgumentError] if the backend is unable to dump the value
    def dump(stored_value, context: nil)
      raise ArgumentError, "Unable to dump a nil value. #{context}" if stored_value.nil?

      locator_key = backend.dump(stored_value)
      raise ArgumentError, "Dump resulted in a nil locator value. #{context}" if locator_key.nil?

      locator_key
    end

  end
end
