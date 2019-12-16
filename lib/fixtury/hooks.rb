# frozen_string_literal: true

require "fixtury/store"

module Fixtury
  module Hooks

    extend ::ActiveSupport::Concern

    included do
      class_attribute :fixtury_dependencies
      self.fixtury_dependencies = Set.new
    end

    module ClassMethods

      def fixtury(*names)
        self.fixtury_dependencies += names.flatten.compact.map(&:to_s)
      end

    end

    def fixtury(name)
      raise ArgumentError unless self.fixtury_dependencies.include?(name.to_s)

      ::Fixtury::Store.instance.get(name)
    end

  end
end
