# frozen_string_literal: true

module Fixtury
  module Errors

    class Base < StandardError

    end

    class AlreadyDefinedError < Base

      def initialize(name)
        super("An element identified by `#{name}` already exists.")
      end

    end

    class CircularDependencyError < Base

      def initialize(name)
        super("One of the dependencies of #{name} is dependent on #{name}.")
      end

    end

    class DefinitionExecutionError < Base

      def initialize(args)
        name, error = args
        super("Error while building definition: '#{name}'. Exception=#{error.inspect}")
      end

    end

    class SchemaNodeNotDefinedError < Base

      def initialize(name)
        super("A schema node identified by `#{name}` does not exist.")
      end

    end

    class SchemaNodeNameInvalidError < Base
      def initialize(parent_name, child_name)
        super("The schema node name `#{child_name}` must start with `#{parent_name}` to be added to it.")
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

    class UnknownFixturyDependency < Base

    end

  end
end
