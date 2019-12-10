# frozen_string_literal: true

require "fixtury/cache"

module Fixtury
  module Minitest

    included do
      class_attribute :fixtury_dependencies
      self.fixtury_dependencies = ::Set.new
    end

    module ClassMethods

      def fixtury(*names)
        self.fixtury_dependencies |= names.flatten.compact.map(&:to_s)
      end

    end

    def before_setup
      ensure_fixturies_loaded
      super
    end

    def ensure_fixturies_loaded
      fixtury_dependencies.each do |name|
        ::Fixtury::Cache.instance.get(name)
      end
    end

    ::Minitest::Test.send(:prepend, self)

  end
end
