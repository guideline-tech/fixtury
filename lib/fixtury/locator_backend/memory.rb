# frozen_string_literal: true

module Fixtury
  module LocatorBackend
    class Memory

      def load(ref)
        ::ObjectSpace._id2ref(ref)
      rescue RangeError
        nil
      end

      def dump(value)
        value.object_id
      end

    end
  end
end
