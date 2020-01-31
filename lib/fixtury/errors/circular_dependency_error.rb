# frozen_string_literal: true

module Fixtury
  module Errors
    class CircularDependencyError < ::StandardError

      def initialize(name)
        super("One of the dependencies of #{name} is dependent on #{name}.")
      end

    end
  end
end
