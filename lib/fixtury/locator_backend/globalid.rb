# frozen_string_literal: true

require "globalid"

module Fixtury
  module LocatorBackend
    class GlobalID

      def load(ref)
        ::GlobalID::Locator.locate ref
      end

      def dump(value)
        value.to_global_id.to_s
      end

    end
  end
end
