# frozen_string_literal: true

require 'forwardable'

module Fixtury
  # A class that contains the definition of a fixture. It also maintains a list of it's
  # dependencies to allow for analysis of the fixture graph.
  class Definition
    include ::Fixtury::SchemaNode
    extend ::Forwardable

    # Initializes a new Definition object.
    #
    # @param deps [Array] An array of dependencies.
    # @param opts [Hash] Additional options for the Definition.
    # @param block [Proc] A block of code to be executed.
    def initialize(deps: [], **opts, &block)
      super(**opts)

      @dependencies = Array(deps).each_with_object({}) do |d, deps|
        parsed_deps = Dependency.from(parent, d)
        parsed_deps.each do |dep|
          existing = deps[dep.accessor]
          raise ArgumentError, "Accessor #{dep.accessor} is already declared by #{existing.search}" if existing

          deps[dep.accessor] = dep
        end
      end

      @callable = block
    end

    # Indicates whether the Definition acts like a Fixtury definition.
    #
    # @return [Boolean] `true` if it acts like a Fixtury definition, `false` otherwise.
    def acts_like_fixtury_definition?
      true
    end

    # Delegates the `call` method to the `callable` object.
    def_delegator :callable, :call

    # Returns the parent schema of the Definition.
    #
    # @return [Object] The parent schema.
    alias schema parent

    attr_reader :callable, :dependencies
  end
end
