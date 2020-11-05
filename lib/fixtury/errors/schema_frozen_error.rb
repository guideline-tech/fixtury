# frozen_string_literal: true

module Fixtury
  module Errors
    class SchemaFrozenError < ::StandardError

      def initialize
        super("Schema is frozen. New namespaces, definitions, and enhancements are not allowed.")
      end

    end
  end
end
