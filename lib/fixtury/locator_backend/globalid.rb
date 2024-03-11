# frozen_string_literal: true

require_relative "./common"
require "globalid"

module Fixtury
  module LocatorBackend
    class GlobalID

      include ::Fixtury::LocatorBackend::Common

      MATCHER = %r{^gid://}.freeze

      def recognizable_key?(locator_value)
        locator_value.is_a?(String) && MATCHER.match?(locator_value)
      end

      def recognizable_value?(stored_value)
        stored_value.respond_to?(:to_global_id)
      end

      def load_reference(locator_value)
        ::GlobalID::Locator.locate locator_value
      end

      def dump_value(stored_value)
        stored_value.to_global_id.to_s
      end

    end
  end
end
