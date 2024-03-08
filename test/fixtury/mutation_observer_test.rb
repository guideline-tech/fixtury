require "test_helper"
require "fixtury/mutation_observer"

module Fixtury
  class MutationObserverTest < ::Test

    uses_db

    def test_the_module_should_be_prepended_to_ar_base_automatically
      assert_includes ::ActiveRecord::Base.included_modules, MutationObserver::ActiveRecordHooks
    end

  end
end
