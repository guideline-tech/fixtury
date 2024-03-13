# frozen_string_literal: true

module Fixtury
  # A Fixtury::SchemaNode implementation that represents a top-level schema
  # or a namespace within a schema.
  class Schema

    include ::Fixtury::SchemaNode

    # @param name [String] the name of the schema, defaults to "" to represent
    # a new top-level schema.
    def initialize(name: "", **options)
      super(name: name, **options)
    end

    def reset
      children.clear
    end

    # Object#acts_like? adherence.
    def acts_like_fixtury_schema?
      true
    end

    # Open up self for child definitions.
    # @param block [Proc] The block to be executed in the context of the schema.
    # @return [Fixtury::Schema] self
    def define(&block)
      instance_eval(&block)
      self
    end

    # Returns "schema" if top-level, otherwise returns "namespace".
    # @return [String] the type of the schema node.
    def schema_node_type
      first_ancestor? ? "schema" : "namespace"
    end

    # Create a child schema at the given relative name. If a child by the name
    # already exists it will be reopened as long as it's a fixtury schema.
    #
    # @param relative_name [String] The relative name of the child schema.
    # @param options [Hash] Additional options for the child schema, applied after instantiation.
    # @param block [Proc] A block of code to be executed in the context of the child schema.
    # @return [Fixtury::Schema] The child schema.
    # @raise [Fixtury::Errors::AlreadyDefinedError] if the child is already defined and not a fixtury schema.
    def namespace(relative_name, **options, &block)
      child = get("./#{relative_name}")

      if child && !child.acts_like?(:fixtury_schema)
        raise Errors::AlreadyDefinedError, child.pathname
      end

      child ||= self.class.new(name: relative_name, parent: self)
      child.apply_options!(options)
      child.instance_eval(&block) if block_given?
      child
    end

    # Create a fixture definition at the given relative name. If the name is already
    # used, a Fixtury::Errors::AlreadyDefinedError will be raised.
    #
    # @param relative_name [String] The relative name of the fixture.
    # @param options [Hash] Additional options for the fixture.
    # @param block [Proc] The block representing the build function of the fixture.
    # @return [Fixtury::Definition] The fixture definition.
    #
    def fixture(relative_name, **options, &block)
      ::Fixtury::Definition.new(
        name: relative_name,
        parent: self,
        **options,
        &block
      )
    end

  end
end
