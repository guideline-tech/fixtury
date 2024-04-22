# frozen_string_literal: true

module Fixtury
  # Provides a mechanism for observing Fixtury lifecycle events.
  class Hooks

    attr_reader :hooks

    def initialize
      @hooks = Hash.new { |h, k| h[k] = { before: [], after: [], around: [], on: [] } }
    end

    # Register a hook to be called around the execution of a trigger.
    # The around hook should ensure the return value is preserved.
    # This also means that the hook itself could modify the return value.
    #
    # @param trigger_type [Symbol] the type of trigger to hook into
    # @param hook [Proc] the hook to be called
    def around(trigger_type, &hook)
      register_hook(trigger_type, :around, hook)
    end

    # Register a hook to be called before the execution of a trigger.
    # (see #register_hook)
    def before(trigger_type, &hook)
      register_hook(trigger_type, :before, hook)
    end

    # Register a hook to be called after the execution of a trigger.
    # The return value will be provided as the first argument to the hook.
    # (see #register_hook)
    def after(trigger_type, &hook)
      register_hook(trigger_type, :after, hook)
    end

    # Similar to after, but the return value is not injected.
    # (see #register_hook)
    def on(trigger_type, &hook)
      register_hook(trigger_type, :on, hook)
    end

    # Trigger the hooks registered for a specific trigger type.
    # :before hooks will be triggered first, followed by :around hooks,
    # :on hooks, and finally :after hooks.
    #
    # @param trigger_type [Symbol] the type of trigger to initiate
    # @param args [Array] arguments to be passed to the hooks
    # @param block [Proc] a block of code to be executed
    # @return [Object] the return value of the block
    def call(trigger_type, *args, &block)
      hook_lists = hooks[trigger_type.to_sym]

      call_inline_hooks(hook_lists[:before], *args)
      return_value = call_around_hooks(hook_lists[:around], 0, block, *args)
      call_inline_hooks(hook_lists[:on], *args)
      call_inline_hooks(hook_lists[:after], return_value, *args)

      return_value
    end

    private

    # Register a hook to be called for a specific trigger type and hook type.
    #
    # @param trigger_type [Symbol] the type of trigger to hook into
    # @param hook_type [Symbol] the point in the trigger to hook into
    # @param hook [Proc] the hook to be called
    # @return [Fixtury::Hooks] the current instance
    def register_hook(trigger_type, hook_type, hook)
      hooks[trigger_type.to_sym][hook_type.to_sym] << hook
      self
    end

    def call_around_hooks(hook_list, idx, block, *args)
      if idx >= hook_list.length
        block.call
      else
        hook_list[idx].call(*args) do
          call_around_hooks(hook_list, idx + 1, block, *args)
        end
      end
    end

    def call_inline_hooks(hook_list, *args)
      hook_list.each do |hook|
        hook.call(*args)
      end
    end
  end
end
