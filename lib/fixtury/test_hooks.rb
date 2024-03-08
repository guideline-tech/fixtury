# frozen_string_literal: true

require "active_support/core_ext/class/attribute"

module Fixtury
  module TestHooks

    extend ::ActiveSupport::Concern

    included do
      class_attribute :fixtury_dependencies
      self.fixtury_dependencies = Set.new
    end

    module ClassMethods

      def fixtury(*names, **opts)
        self.fixtury_dependencies += names.flatten.map do |name|
          name.start_with?("/") ? name : "/#{name}"
        end.compact.map(&:to_s)

        accessor_option = opts[:as]
        accessor_option = opts[:accessor] if accessor_option.nil? # old version, backwards compatability
        accessor_option = accessor_option.nil? ? true : accessor_option

        if accessor_option

          if accessor_option != true && names.length > 1
            raise ArgumentError, "A named :as option is only available when providing one fixture"
          end

          names.each do |fixture_name|
            method_name = accessor_option == true ? fixture_name.split("/").last : accessor_option
            ivar = :"@#{method_name}"

            class_eval <<-EV, __FILE__, __LINE__ + 1
              def #{method_name}
                return #{ivar} if defined?(#{ivar})

                value = fixtury("#{fixture_name}")
                #{ivar} = value
              end
            EV
          end
        end
      end

    end

    def fixtury(name)
      return nil unless fixtury_store

      name = name.to_s
      name = "/#{name}" unless name.start_with?("/")

      unless fixtury_dependencies.include?(name)
        raise Errors::UnknownFixturyDependency, "Unrecognized fixtury dependency `#{name}` for #{self.class}"
      end

      fixtury_store.get(name)
    end

    def fixtury_store
      ::Fixtury.store
    end

    def fixtury_loaded?(name)
      return false unless fixtury_store

      fixtury_store.loaded?(name)
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
      return unless fixtury_use_transactions?

      clear_expired_fixtury_fixtures!
      load_all_fixtury_fixtures!

      fixtury_database_connections.each do |conn|
        conn.begin_transaction joinable: false
      end
    end

    def teardown_fixtury_fixtures
      return unless fixtury_use_transactions?

      fixtury_database_connections.each do |conn|
        conn.rollback_transaction if conn.open_transactions.positive?
      end
    end

    def clear_expired_fixtury_fixtures!
      return unless fixtury_store

      fixtury_store.clear_expired_references!
    end

    def load_all_fixtury_fixtures!
      fixtury_dependencies.each do |name|
        unless fixtury_loaded?(name)
          ::Fixtury.log("preloading #{name.inspect}", name: "test", level: ::Fixtury::LOG_LEVEL_INFO)
          fixtury(name)
        end
      end
    end

    def fixtury_use_transactions?
      return use_transactional_tests if respond_to?(:use_transactional_tests)
      return use_transactional_fixtures if respond_to?(:use_transactional_fixtures)

      true
    end

  end
end
