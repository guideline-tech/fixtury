# frozen_string_literal: true

module Fixtury
  module LocatorBackend
    module Common

      def recognizable_key?(_locator_value)
        raise NotImplementedError
      end

      def recognizable_value?(_stored_value)
        raise NotImplementedError
      end

      def load_reference(_locator_value)
        raise NotImplementedError
      end

      def dump_value(_stored_value)
        raise NotImplementedError
      end

      def load(locator_value)
        return load_reference(locator_value) if recognizable_key?(locator_value)

        case locator_value
        when Array
          locator_value.map { |subvalue| self.load(subvalue) }
        when Hash
          locator_value.each_with_object({}) do |(k, subvalue), h|
            h[k] = self.load(subvalue)
          end
        else
          raise Errors::UnrecognizableLocatorError.new(:load, locator_value)
        end
      end

      def dump(stored_value)
        return dump_value(stored_value) if recognizable_value?(stored_value)

        case stored_value
        when Array
          stored_value.map { |subvalue| dump(subvalue) }
        when Hash
          stored_value.each_with_object({}) do |(k, subvalue), h|
            h[k] = dump(subvalue)
          end
        else
          raise Errors::UnrecognizableLocatorError.new(:dump, stored_value)
        end
      end

    end
  end
end
