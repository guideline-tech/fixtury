# frozen_string_literal: true

require "fixtury"
require "active_support/core_ext/class/attribute"

module Fixtury
  module TestHooks

    def self.prepended(klass)
      klass.class_attribute :fixtury_dependencies
      klass.fixtury_dependencies = Set.new
      klass.extend ClassMethods
    end

    def self.included(klass)
      raise ArgumentError, "#{name} should be prepended, not included"
    end

    module ClassMethods

      def fixtury_store
        ::Fixtury.store
      end

      def fixtury_schema
        ::Fixtury.schema
      end

      def fixtury(*searches, **opts)
        pathnames = searches.map do |search|
          dfn = fixtury_schema.get!(search)
          dfn.pathname
        end

        self.fixtury_dependencies += pathnames

        accessor_option = opts[:as]
        accessor_option = opts[:accessor] if accessor_option.nil? # old version, backwards compatability
        accessor_option = accessor_option.nil? ? true : accessor_option

        if accessor_option

          if accessor_option != true && pathnames.length > 1
            raise ArgumentError, "A named :as option is only available when providing one fixture"
          end

          pathnames.each do |pathname|
            method_name = (accessor_option == true ? pathname.split("/").last : accessor_option).to_sym

            if method_defined?(method_name)
              raise ArgumentError, "A method by the name of #{method_name} already exists in #{self}"
            end

            ivar = :"@fixtury_#{method_name}"

            class_eval <<-EV, __FILE__, __LINE__ + 1
              def #{method_name}
                return #{ivar} if defined?(#{ivar})

                #{ivar} = fixtury("#{pathname}")
              end
            EV
          end
        end
      end

    end

    def before_setup(...)
      fixtury_setup if fixtury_dependencies.any?
      super
    end

    def after_teardown(...)
      super
      fixtury_teardown if fixtury_dependencies.any?
    end


    def fixtury(name)
      return nil unless self.class.fixtury_store

      dfn = self.class.fixtury_schema.get!(name)

      unless fixtury_dependencies.include?(dfn.pathname)
        raise Errors::UnknownTestDependencyError, "Unrecognized fixtury dependency `#{dfn.pathname}` for #{self.class}"
      end

      self.class.fixtury_store.get(dfn.pathname)
    end

    def fixtury_loaded?(name)
      return false unless self.class.fixtury_store

      self.class.fixtury_store.loaded?(name)
    end

    def fixtury_database_connections
      ActiveRecord::Base.connection_handler.connection_pool_list(:writing).map(&:connection)
    end

    def fixtury_setup
      fixtury_clear_stale_fixtures!
      fixtury_load_all_fixtures!
      return unless fixtury_use_transactions?

      fixtury_database_connections.each do |conn|
        conn.begin_transaction joinable: false
      end
    end

    def fixtury_teardown
      return unless fixtury_use_transactions?

      fixtury_database_connections.each do |conn|
        conn.rollback_transaction if conn.open_transactions.positive?
      end
    end

    def fixtury_clear_stale_fixtures!
      return unless self.class.fixtury_store

      self.class.fixtury_store.clear_stale_references!
    end

    def fixtury_load_all_fixtures!
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
