# frozen_string_literal: true

require "fixtury/errors/unrecognizable_locator_error"

module Fixtury
  module LocatorBackend
    module Common

      def recognized_reference?(_ref)
        raise NotImplementedError
      end

      def recognized_value?(_value)
        raise NotImplementedError
      end

      def load_recognized_reference(_ref)
        raise NotImplementedError
      end

      def dump_recognized_value(_value)
        raise NotImplementedError
      end

      def load(ref)
        return load_recognized_reference(ref) if recognized_reference?(ref)

        case ref
        when Array
          ref.map { |subref| self.load(subref) }
        when Hash
          ref.each_with_object({}) do |(k, subref), h|
            h[k] = self.load(subref)
          end
        else
          raise ::Fixtury::Errors::UnrecognizableLocatorError.new(:load, ref)
        end
      end

      def dump(value)
        return dump_recognized_value(value) if recognized_value?(value)

        case value
        when Array
          value.map { |subvalue| dump(subvalue) }
        when Hash
          ref.each_with_object({}) do |(k, subvalue), h|
            h[k] = dump(subvalue)
          end
        else
          raise ::Fixtury::Errors::UnrecognizableLocatorError.new(:dump, value)
        end
      end

    end
  end
end
