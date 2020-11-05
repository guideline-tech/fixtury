# frozen_string_literal: true

module Fixtury
  module Errors
    class OptionCollisionError < ::StandardError

      def initialize(schema_name, option_key, old_value, new_value)
        super("The #{schema_name.inspect} schema #{option_key.inspect} option value of #{old_value.inspect} conflicts with the new value #{new_value.inspect}.")
      end

    end
  end
end
