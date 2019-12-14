# frozen_string_literal: true

require "fixtury/store"

module Fixtury
  module Minitest

    def self.fixtury_dependencies
      @fixtury_dependencies ||= Set.new
    end

    included do
      class_attribute :fixtury_dependencies
      self.fixtury_dependencies = ::Set.new
    end

    module ClassMethods

      def fixtury(*names)
        ::Fixtury::Minitest.fixtury_dependencies
        names.flatten.compact.each do |n|
          ::Fixtury::Minitest.fixtury_dependencies << n.to_s
        end
      end

    end

    def fixtury(name)
      raise ArgumentError unless fixtury_dependencies.include?(name.to_s)

      ::Fixtury::Store.instance.get(name)
    end

    ::Minitest::Test.send(:prepend, self)

  end
end
