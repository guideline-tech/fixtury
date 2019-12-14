# frozen_string_literal: true

module Fixtury
  module Errors
    class AlreadyDefinedError < ::StandardError

      def initialize(name)
        super("An element identified by `#{name}` already exists.")
      end

    end
  end
end
