# frozen_string_literal: true

require "active_support/lazy_load_hooks"

module Fixtury
  # The mutation observer class is responsible for tracking the isolation level of resources as they are created and updated.
  # If a resource is created in one isolation level, but updated in another, the mutation observer will raise an error.
  # If Rails is present, the Railtie will hook into ActiveRecord to automatically report these changes to the MutationObserver
  module MutationObserver

    # Hooks into the lifecycle of an ActiveRecord::Base object to report changes to the MutationObserver.
    # This is automatically prepended to ActiveRecord::Base when Rails is present.
    module ActiveRecordHooks

      def _create_record(*args)
        result = super
        MutationObserver.on_record_create(self)
        result
      end

      def _update_record(**args)
        MutationObserver.on_record_update(self, changes)
        super
      end

      def update_columns(changes)
        MutationObserver.on_record_update(self, changes)
        super
      end

    end

    class << self

      attr_reader :current_execution

      def log(msg, level: ::Fixtury::LOG_LEVEL_DEBUG)
        ::Fixtury.log(msg, name: "mutation_observer", level: level)
      end

      def owners
        @owners ||= {}
      end

      def reported_owner(locator_key)
        owners[locator_key]
      end

      # Observe mutation activity while the given block is executed.
      #
      # @param execution [Fixtury::Execution] The execution that is currently being observed.
      # @yield [void] The block to execute while observing the given execution.
      def observe(execution)
        prev_execution = current_execution
        @current_execution = execution
        yield
      ensure
        @current_execution = prev_execution
      end

      # The isolation key of the current definition associated with the current execution.
      #
      # @return [String, nil] The isolation key of the current definition, or nil if there is no current definition.
      def current_isolation_key
        current_definition&.isolation_key
      end

      # The definition associated with the current execution.
      #
      # @return [Fixtury::Definition, nil] The definition associated with the current execution, or nil if there is no current execution.
      def current_definition
        current_execution&.definition
      end

      # Since there may be inheritance at play, we use the base class to consolidate
      # ensure the same db record always produces the same locator key by using the
      # base class to generate the locator key.
      #
      # @param obj [ActiveRecord::Base] The object to generate a locator key for.
      # @return [String, nil] The locator key for the given object, or nil if there is no current execution.
      def normalized_locator_key(obj)
        return nil unless current_execution

        pk = obj.class.primary_key
        delegate_object = obj.class.base_class.new(pk => obj.read_attribute(pk))
        current_execution.store.locator.dump(delegate_object, context: "<mutation_observer>")
      end

      # When a record is created we assign ownership to the current isolation key, if present.
      #
      # @param obj [ActiveRecord::Base] The record that was created.
      # @return [void]
      def on_record_create(obj)
        locator_key = normalized_locator_key(obj)
        return unless locator_key

        log("Setting isolation level of #{locator_key.inspect} to #{current_isolation_key.inspect} via #{current_definition.inspect}")
        owners[locator_key] = current_isolation_key
      end

      # When a record is updated we check to see if the reported owner matches the current isolation key.
      # If it doesn't, we raise an error.
      #
      # @param obj [ActiveRecord::Base] The record that was updated.
      # @param changes [Hash] The changes that were made to the record.
      # @return [void]
      # @raise [Fixtury::Errors::IsolatedMutationError] if the record is updated in a different isolation level than it was created in.
      def on_record_update(obj, changes)
        return if changes.blank?

        locator_key = normalized_locator_key(obj)
        log("verifying record update for #{locator_key}")

        actual_owner = reported_owner(locator_key)
        return unless actual_owner

        if current_isolation_key.nil?
          log("Allowing update to #{locator_key.inspect} because there is no registered owner.")
          return
        end

        if actual_owner == current_isolation_key
          log("Allowing update to #{locator_key.inspect} in the #{actual_owner.inspect} isolation level via #{current_definition.inspect}.")
          return
        end

        raise Errors::IsolatedMutationError,  "Cannot modify #{locator_key.inspect}. Owned by: #{actual_owner.inspect}. Modified by: #{current_isolation_key.inspect}. Requested changes: #{changes.inspect}"
      end

    end
  end
end

# Observe all executions and report changes to the MutationObserver.
::Fixtury.hooks.around(:execution) do |execution, &block|
  ::Fixtury::MutationObserver.observe(execution, &block)
end
