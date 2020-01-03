# frozen_string_literal: true

require_relative "./common"
require "globalid"

module Fixtury
  module LocatorBackend
    class GlobalID

      include ::Fixtury::LocatorBackend::Common

      MATCHER = %r{^gid://}.freeze

      def recognized_reference?(ref)
        ref.is_a?(String) && MATCHER.match?(ref)
      end

      def recognized_value?(val)
        val.respond_to?(:to_global_id)
      end

      def load_recognized_reference(ref)
        ::GlobalID::Locator.locate ref
      end

      def dump_recognized_value(value)
        value.to_global_id.to_s
      end

    end
  end
end
