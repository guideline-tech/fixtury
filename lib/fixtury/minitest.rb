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

    def fixtury(name)
      raise ArgumentError unless fixtury_dependencies.include?(name.to_s)

      ::Fixtury::Cache.instance.get(name)
    end

    ::Minitest::Test.send(:prepend, self)

  end
end

class Test

  fixtury "users.a"

  let(:user) { fixtury("users.a") }

end
