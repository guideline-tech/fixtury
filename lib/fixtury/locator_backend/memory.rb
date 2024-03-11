# frozen_string_literal: true

require_relative "./common"

module Fixtury
  module LocatorBackend
    class Memory

      include ::Fixtury::LocatorBackend::Common

      MATCHER = /^fixtury-oid-(?<object_id>[\d]+)$/.freeze

      def recognizable_key?(locator_value)
        locator_value.is_a?(String) && MATCHER.match?(locator_value)
      end

      def recognizable_value?(_stored_value)
        true
      end

      def load_reference(locator_value)
        match = MATCHER.match(locator_value)
        return nil unless match

        ::ObjectSpace._id2ref(match[:object_id].to_i)
      rescue RangeError
        nil
      end

      def dump_value(stored_value)
        "fixtury-oid-#{stored_value.object_id}"
      end

    end
  end
end
