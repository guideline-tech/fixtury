# frozen_string_literal: true

require "fixtury/store"
require "active_support/core_ext/class/attribute"

module Fixtury
  module TestHooks

    extend ::ActiveSupport::Concern

    included do
      class_attribute :fixtury_dependencies
      self.fixtury_dependencies = Set.new

      class_attribute :local_fixtury_dependencies
      self.local_fixtury_dependencies = Set.new
    end

    module ClassMethods

      def fixtury(*names, &definition)
        opts = names.extract_options!

        # define fixtures if blocks are given
        if block_given?
          raise ArgumentError, "A fixture cannot be defined in an anonymous class" if name.nil?

          namespace = fixtury_namespace

          ns = ::Fixtury.schema

          namespace.split("/").each do |ns_name|
            ns = ns.namespace(ns_name){}
          end

          names.each do |fixture_name|
            ns.fixture(fixture_name, &definition)
            self.local_fixtury_dependencies += ["/#{namespace}/#{fixture_name}"]
          end

        # otherwise, just record the dependency
        else
          self.fixtury_dependencies += names.flatten.compact.map(&:to_s)
        end

        accessor_option = opts.key?(:accessor) ? opts[:accessor] : true

        if accessor_option

          if accessor_option != true && names.length > 1
            raise ArgumentError, "A named :accessor option is only available when providing one fixture"
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

      def fixtury_namespace
        name.underscore
      end

    end

    def fixtury(name)
      return nil unless fixtury_store

      name = name.to_s

      local_alias = "/#{self.class.fixtury_namespace}/#{name}"
      if self.local_fixtury_dependencies.include?(local_alias)
        return fixtury_store.get(local_alias, execution_context: self)
      end

      unless self.fixtury_dependencies.include?(name)
        raise ArgumentError, "Unrecognized fixtury dependency `#{name}` for #{self.class}"
      end

      fixtury_store.get(name, execution_context: self)
    end

    def fixtury_store
      ::Fixtury::Store.instance
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
      if fixtury_dependencies.any? || local_fixtury_dependencies.any?
        setup_fixtury_fixtures
      else
        super
      end
    end

    # piggybacking activerecord fixture setup for now.
    def teardown_fixtures(*args)
      if fixtury_dependencies.any? || local_fixtury_dependencies.any?
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
      return unless fixtury_store

      fixtury_store.clear_expired_references!
    end

    def load_all_fixtury_fixtures!
      (fixtury_dependencies | local_fixtury_dependencies).each do |name|
        fixtury(name) unless fixtury_loaded?(name)
      end
    end

  end
end
