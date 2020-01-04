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

    def fixtury_loaded?(name)
      ::Fixtury::Store.instance.loaded?(name)
    end

    def fixtury_database_connections
      ActiveRecord::Base.connection_handler.connection_pool_list.map(&:connection)
    end

    # piggybacking activerecord fixture setup for now.
    def setup_fixtures(*args)
      if fixtury_dependencies.any?
        setup_fixtury_fixtures
      else
        super
      end
    end

    # piggybacking activerecord fixture setup for now.
    def teardown_fixtures(*args)
      if fixtury_dependencies.any?
        teardown_fixtury_fixtures
      else
        super
      end
    end

    def setup_fixtury_fixtures
      return unless use_transactional_fixtures

      clear_expired_fixtury_fixtures!
      load_all_fixtury_fixtures!

      fixtury_database_connections.each do |conn|
        conn.begin_transaction joinable: false
      end
    end

    def teardown_fixtury_fixtures
      return unless use_transactional_fixtures

      fixtury_database_connections.each(&:rollback_transaction)
    end

    def clear_expired_fixtury_fixtures!
      ::Fixtury::Store.instance.clear_expired_references!
    end

    def load_all_fixtury_fixtures!
      fixtury_dependencies.each do |name|
        fixtury(name) unless fixtury_loaded?(name)
      end
    end

  end
end
