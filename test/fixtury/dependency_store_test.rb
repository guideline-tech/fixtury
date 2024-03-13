require "test_helper"

module Fixtury
  class DependencyStoreTest < ::Test

    let(:store) { Fixtury.store }
    # dfn has an "earth" dependency on "../earth"
    let(:dfn) { Fixtury.schema.get("countries/towns/relative_town") }
    let(:dep_store) { Fixtury::DependencyStore.new(definition: dfn, store: store) }

    def setup
      super
      load_default_fixtures
    end

    def test_the_store_provides_access_to_dependencies_of_the_definition
      assert_equal "Relative Earth", dep_store["earth"]
      assert_equal "Relative Earth", dep_store[:earth]

      assert_raises Errors::UnknownDependencyError do
        dep_store["absolute_town"]
      end
    end

    def test_the_store_can_provide_access_via_method_missing
      dep_store.respond_to?(:earth)
      assert_equal "Relative Earth", dep_store.earth
    end

    def test_the_store_will_back_up_to_searching_if_strict_dependencies_is_disabled
      ::Fixtury.configuration.stubs(:strict_dependencies).returns(false)
      assert_equal "Town, Earth", dep_store.get("./absolute_town")
    end

  end
end
