# frozen_string_literal: true

require "fixtury/store"

module Fixtury
  module Minitest

    included do
      class_attribute :fixtury_set
      self.fixtury_set = Set.new
    end

    module ClassMethods

      def fixtury(*names)
        self.fixtury_set |= names.flatten.compact.map(&:to_s)
      end

    end

    def before_setup
      ensure_fixturies_loaded
      super
    end

    def ensure_fixturies_loaded
      fixtury_set.each do |name|
        ::Fixtury::Store.instance.get(name)
      end
    end

    ::Minitest::Test.send(:prepend, self)
  end
end
