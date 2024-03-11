require "test_helper"
require "fixtury/mutation_observer"
require "fixtury/locator_backend/globalid"

module Fixtury
  class MutationObserverTest < ::Test

    uses_db

    let :locator do
      ::Fixtury::Locator.new(
        backend: ::Fixtury::LocatorBackend::GlobalID.new
      )
    end

    def setup
      super

      MutationObserver.owners.clear

      ::Fixtury.define do
        fixture(:user) { Support::Db::User.create!(first_name: "Doug", last_name: "Wilson") }
        fixture(:updated_user, deps: "user") { |deps| deps.user.tap { |u| u.update(first_name: "Douglas") } }

        namespace "isolated", isolate: true do
          fixture(:user) { Support::Db::User.create!(first_name: "Dave", last_name: "Wilson") }
          fixture(:updated_user, deps: "user") { |deps| deps.user.tap { |u| u.update(first_name: "David") } }
        end
      end

      ::Fixtury.store = ::Fixtury::Store.new(locator: locator)
    end

    def test_the_module_should_be_prepended_to_ar_base_automatically
      assert_includes ::ActiveRecord::Base.included_modules, MutationObserver::ActiveRecordHooks
    end

    def test_when_a_record_is_created_the_mutation_observer_sees_it
      assert_equal 0, MutationObserver.owners.size

      user = ::Fixtury.store.get("user")
      refute_nil user

      assert_equal({
        user.to_global_id.to_s => "/user"
      }, MutationObserver.owners)
    end

    def test_when_a_record_is_updated_the_mutation_observer_is_alerted
      test_when_a_record_is_created_the_mutation_observer_sees_it
      assert_raises Fixtury::Errors::IsolatedMutationError do
        ::Fixtury.store.get("updated_user")
      end
    end

    def test_a_record_is_associated_with_the_closest_declared_isolation_key
      assert_equal 0, MutationObserver.owners.size
      user = ::Fixtury.store.get("isolated/user")
      refute_nil user

      assert_equal({
        user.to_global_id.to_s => "/isolated"
      }, MutationObserver.owners)
    end

    def test_a_record_in_the_same_isolation_level_can_be_updated_by_another_fixture
      assert_equal 0, MutationObserver.owners.size

      refute ::Fixtury.store.loaded?("isolated/user")
      refute ::Fixtury.store.loaded?("isolated/updated_user")

      user = ::Fixtury.store.get("isolated/user")
      assert_equal "David", user.first_name

      assert ::Fixtury.store.loaded?("isolated/user")
      assert ::Fixtury.store.loaded?("isolated/updated_user")

      assert_equal({
        user.to_global_id.to_s => "/isolated"
      }, MutationObserver.owners)

      assert_equal({
        "/isolated" => true
      }, ::Fixtury.store.loaded_isolation_keys)
    end

  end
end
