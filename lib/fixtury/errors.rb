# frozen_string_literal: true

module Fixtury
  module Errors

    class Base < StandardError

    end

    class AlreadyDefinedError < Base

      def initialize(name)
        super("An element identified by #{name.inspect} already exists.")
      end

    end

    class CircularDependencyError < Base

      def initialize(name)
        super("One of the dependencies of #{name.inspect} is dependent on #{name.inspect}.")
      end

    end

    class DefinitionExecutionError < Base

      attr_reader :original_error

      def initialize(pathname, error)
        @original_error = error
        super("Error while building #{pathname.inspect}: #{original_error}")
        set_backtrace(original_error.backtrace)
      end

    end

    class SchemaNodeNotDefinedError < Base

      def initialize(pathname, search)
        super("A schema node identified by #{search.inspect} could not be found from #{pathname.inspect}.")
      end

    end

    class SchemaNodeNameInvalidError < Base
      def initialize(parent_name, child_name)
        super("The schema node name #{child_name.inspect} must start with #{parent_name.inspect} to be added to it.")
      end
    end

    class OptionCollisionError < Base

      def initialize(schema_name, option_key, old_value, new_value)
        super("The #{schema_name.inspect} schema #{option_key.inspect} option value of #{old_value.inspect} conflicts with the new value #{new_value.inspect}.")
      end

    end

    class UnrecognizableLocatorError < Base

      def initialize(action, thing)
        super("Locator did not recognize #{thing} during #{action}")
      end

    end

    class IsolatedMutationError < Base

    end

    class UnknownTestDependencyError < Base

    end

    class UnknownDependencyError < Base

      def initialize(defn, key)
        super("#{defn.pathname} does not contain the provided dependency: #{key}")
      end

    end

  end
end
