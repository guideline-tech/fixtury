# frozen_string_literal: true

require "fixtury/locator_backend/memory"

module Fixtury
  class Locator

    def self.instance
      @instance ||= new(backend: ::Fixtury::LocatorBackend::Memory.new)
    end

    attr_reader :backend

    def initialize(backend:)
      @backend = backend
    end

    def load(ref)
      raise ArgumentError, "Unable to load a nil ref" if ref.nil?

      backend.load(ref)
    end

    def dump(value)
      raise ArgumentError, "Unable to dump a nil value" if value.nil?

      ref = backend.dump(value)
      raise ArgumentError, "The value resulted in a nil ref" if ref.nil?

      ref
    end

  end
end
