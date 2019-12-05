# frozen_string_literal: true

module Fixtury
  module Errors
    class FixtureNotDefinedError < ::StandardError

      def initialize(name)
        super("A fixture identified by #{name} does not exist.")
      end

    end
  end
end
