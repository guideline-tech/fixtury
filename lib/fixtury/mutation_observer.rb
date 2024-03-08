# frozen_string_literal: true

module Fixtury
  # The mutation observer class is responsible for tracking the isolation level of resources as they are created and updated.
  # If a resource is created in one isolation level, but updated in another, the mutation observer will raise an error.
  # If Rails is present, the Railtie will hook into ActiveRecord to automatically report these changes to the MutationObserver
  module MutationObserver

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

      def observe(execution)
        prev_execution = current_execution
        @current_execution = execution
        yield
      ensure
        @current_execution = prev_execution
      end

      def current_isolation_key
        return nil unless current_execution

        current_execution.definition.options.fetch(:isolation_key, nil)
      end

      # This is to ensure that ownership is represented by a base_class implementation rather than a subclass.
      def normalized_locator_key(obj)
        return nil unless current_execution

        delegate_object = obj.base_class.new(id: obj.id)
        current_execution.store.locator.dump(delegate_object)
      end

      def on_record_create(obj)
        locator_key = normalized_locator_key(obj)
        return unless locator_key


        log("Setting isolation level of #{locator_key.inspect} to #{current_isolation_key.inspect} via #{current_definition.inspect}")
        owners[locator_key] = current_isolation_key
      end

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

::Fixtury.hooks.around(:execution) do |execution, &block|
  MutationObserver.observe(execution, &block)
end
