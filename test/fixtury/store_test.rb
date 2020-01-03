# frozen_string_literal: true

require "test_helper"
require "fixtury/store"
require "fixtury/schema"

module Fixtury
  class StoreTest < ::Test

    let(:schema) do
      ::Fixtury::Schema.new(parent: nil, name: "test").define do
        fixture "foo" do
          "foo"
        end

        fixture "bar" do
          "bar"
        end
      end
    end

    let(:circular_schema) do
      ::Fixtury::Schema.new(parent: nil, name: "test").define do
        fixture "foo" do |s|
          s["bar"]
        end

        fixture "bar" do |s|
          s["baz"]
        end

        fixture "baz" do |s|
          s["foo"]
        end
      end
    end

    def test_a_store_holds_references_to_fixtures
      store = ::Fixtury::Store.new(schema: schema)
      assert_equal true, store.references.empty?

      t = Time.now.to_i
      assert_equal "foo", store["foo"]
      ref = store.references["/test/foo"]

      assert_equal "/test/foo", ref.name
      assert_equal "foo".object_id, ref.value
      assert_equal t, ref.created_at
    end

    def test_a_store_returns_an_existing_reference_rather_than_reinvoking_the_definition
      store = ::Fixtury::Store.new(schema: schema)
      ::Fixtury::Definition.any_instance.expects(:call).once.returns("baz")

      assert_equal "baz", store["foo"]
      assert_equal "baz", store["foo"]
    end

    def test_a_ttl_store_does_not_return_expired_refs
      ttl = 10
      ttl_store = ::Fixtury::Store.new(schema: schema, ttl: ttl)
      ::Fixtury::Definition.any_instance.expects(:call).twice.returns("baz")

      t = Time.now
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

    def test_a_store_doesnt_allow_circular_references
      store = ::Fixtury::Store.new(schema: circular_schema)
      assert_raises ::Fixtury::Errors::CircularDependencyError do
        store["foo"]
      end
      assert_raises ::Fixtury::Errors::CircularDependencyError do
        store["bar"]
      end
      assert_raises ::Fixtury::Errors::CircularDependencyError do
        store["baz"]
      end
    end

  end
end
