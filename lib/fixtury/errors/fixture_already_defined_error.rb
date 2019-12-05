# frozen_string_literal: true

module Fixtury
  module Errors
    class FixtureAlreadyDefinedError < ::StandardError

      def initialize(name)
        super("A fixture identified by #{name} already exists.")
      end

    end
  end
end
