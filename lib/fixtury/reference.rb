# frozen_string_literal: true

module Fixtury
  # Acts as an reference between the schema and an object in some remote store.
  # The Store uses these references to keep track of the fixtures it has created.
  # The references are used by the locator to retrieve the fixture data from whatever
  # backend is being used.
  class Reference

    # A special key used to indicate that the a definition is currently building an
    # object for this locator_key. This is used to prevent circular dependencies.
    HOLDER_KEY = "__BUILDING_FIXTURE__"

    def self.holder(name)
      new(name, HOLDER_KEY)
    end

    attr_reader :name, :locator_key, :created_at, :metadata
    alias options metadata # backwards compatibility

    def initialize(name, locator_key, **metadata)
      @name = name
      @locator_key = locator_key
      @created_at = Time.now.to_i
      @metadata = metadata
    end

    def holder?
      locator_key == HOLDER_KEY
    end

    def real?
      !holder?
    end

  end
end
