# frozen_string_literal: true

require "test_helper"
require "fixtury/store"
require "fixtury/schema"

module Fixtury
  class StoreTest < ::Test

    let(:schema) do
      ::Fixtury::Schema.new(parent: nil, name: "test").define do
        fixture("foo") { "foo" }
        fixture("bar") { "bar" }
      end
    end

    let(:circular_schema) do
      ::Fixtury::Schema.new(parent: nil, name: "test").define do
        fixture("foo", deps: "bar") { |s| s["bar"] }
        fixture("bar", deps: "baz") { |s| s["baz"] }
        fixture("baz", deps: "foo") { |s| s["foo"] }
      end
    end

    def test_a_store_holds_references_to_fixtures
      store = ::Fixtury::Store.new(schema: schema)
      assert_equal true, store.references.empty?

      t = Time.now.to_i
      assert_equal "foo", store["foo"]
      ref = store.references["/test/foo"]

      assert_equal "/test/foo", ref.name
      assert_equal "fixtury-oid-#{Process.pid}-#{"foo".object_id}", ref.locator_key
      assert_equal t, ref.created_at
    end

    def test_a_store_returns_an_existing_reference_rather_than_reinvoking_the_definition
      store = ::Fixtury::Store.new(schema: schema)
      output = DefinitionExecutor::Output.new
      output.stubs(:value).returns("baz")
      Fixtury::DefinitionExecutor.any_instance.expects(:call).once.returns(output)

      assert_equal "baz", store["foo"]
      assert_equal "baz", store["foo"]
    end

    def test_a_ttl_store_does_not_return_expired_refs
      ttl = 10
      ttl_store = ::Fixtury::Store.new(schema: schema)
      ttl_store.stubs(:ttl).returns(ttl)

      t = Time.now
      Time.stubs(:now).returns(t)
      ttl_store["foo"]
      ref = ttl_store.references["/test/foo"]

      assert_equal t.to_i, ref.created_at

      # not expired yet, returns the same ref
      Time.stubs(:now).returns(t + ttl)
      ref = ttl_store.references["/test/foo"]
      assert_equal t.to_i, ref.created_at

      # now we're expired, it should call the definition again and build a new ref
      Time.stubs(:now).returns(t + ttl + 1)
      ttl_store["foo"]
      new_ref = ttl_store.references["/test/foo"]

      refute_equal ref.created_at, new_ref.created_at
    end

    def test_generated_references_hold_metadata
      dfn = schema.get("foo")
      dfn.stubs(:isolation_key).returns("some_isolation_key")
      store = ::Fixtury::Store.new(schema: schema)
      output = DefinitionExecutor::Output.new
      output.stubs(:value).returns("baz")
      output.stubs(:metadata).returns({ meta_foo: "metabar" })
      Fixtury::DefinitionExecutor.any_instance.expects(:call).once.returns(output)

      store.get("foo")
      ref = store.references[dfn.pathname]

      assert_equal({
        isolation_key: "some_isolation_key",
        meta_foo: "metabar"
      }, ref.metadata)
    end

    def test_a_store_doesnt_allow_circular_references
      store = ::Fixtury::Store.new(schema: circular_schema)
      assert_raises Errors::CircularDependencyError do
        store["foo"]
      end
      assert_raises Errors::CircularDependencyError do
        store["bar"]
      end
      assert_raises Errors::CircularDependencyError do
        store["baz"]
      end
    end

    def test_store_reloads_value_if_locator_cannot_find
      store = ::Fixtury::Store.new(schema: schema)
      output = DefinitionExecutor::Output.new
      output.stubs(:value).returns("baz")
      Fixtury::DefinitionExecutor.any_instance.expects(:call).twice.returns(output)

      assert_equal "baz", store["foo"]
      store.locator.stubs(:load).returns(nil)

      assert_equal "baz", store["foo"]
    end

  end
end
