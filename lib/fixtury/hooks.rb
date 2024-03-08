# frozen_string_literal: true

module Fixtury
  class Hooks

    attr_reader :hooks

    def initialize
      @hooks = Hash.new { |h, k| h[k] = { before: [], after: [], around: [] } }
    end

    def around(trigger_type, &hook)
      hooks[trigger_type.to_sym][:around] << hook
    end

    def before(trigger_type, &hook)
      hooks[trigger_type.to_sym][:before] << hook
    end

    def after(trigger_type, &hook)
      hooks[trigger_type.to_sym][:after] << hook
    end

    def call(trigger_type, *args, &block)
      hook_lists = hooks[trigger_type.to_sym]

      call_inline_hooks(hook_lists[:before], *args)
      return_value = call_around_hooks(hook_lists[:around], 0, block, *args)
      call_inline_hooks(hook_lists[:after], return_value, *args)

      return_value
    end

    private

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