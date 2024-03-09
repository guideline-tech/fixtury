# frozen_string_literal: true

module Fixtury
  class Schema

    include ::Fixtury::SchemaNode

    def initialize(name: "", **options)
      super(name: name, **options)
    end

    def acts_like_fixtury_schema?
      true
    end

    def define(&block)
      instance_eval(&block)
      self
    end

    def schema_node_type
      first_ancestor? ? "schema" : "ns"
    end

    def namespace(name, **options, &block)
      child = get("./#{name}")

      if child && !child.acts_like?(:fixtury_schema)
        raise Errors::AlreadyDefinedError, child.pathname
      end

      child ||= self.class.new(name: name, parent: self)
      child.apply_options!(options)
      child.instance_eval(&block) if block_given?
      child
    end

    def fixture(name, **options, &block)
      ::Fixtury::Definition.new(
        name: name,
        parent: self,
        **options,
        &block
      )
    end

  end
end
