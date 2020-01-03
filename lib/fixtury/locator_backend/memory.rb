# frozen_string_literal: true

require_relative "./common"

module Fixtury
  module LocatorBackend
    class Memory

      include ::Fixtury::LocatorBackend::Common

      MATCHER = /^fixtury-oid-(?<object_id>[\d]+)$/.freeze

      def recognized_reference?(ref)
        ref.is_a?(String) && MATCHER.match?(ref)
      end

      def recognized_value?(_val)
        true
      end

      def load_recognized_reference(ref)
        match = MATCHER.match(ref)
        return nil unless match

        ::ObjectSpace._id2ref(match[:object_id].to_i)
      rescue RangeError
        nil
      end

      def dump_recognized_value(value)
        "fixtury-oid-#{value.object_id}"
      end

    end
  end
end
