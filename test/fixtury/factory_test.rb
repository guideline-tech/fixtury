# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Fixtury
  class FactoryTest < ::Test

    def before_setup
      super
      ::Fixtury.stores.clear
    end

    def teardown
      ::Fixtury.configuration.filepath = nil
      ::Fixtury.stores.clear
      super
    end

    def test_factory_invokes_the_definition_every_time
      built = []
      ::Fixtury.define do
        fixture("record") do
          built << :record
          "record-#{built.length}"
        end
      end

      assert_equal "record-1", ::Fixtury.factory("record")
      assert_equal "record-2", ::Fixtury.factory("record")
      assert_equal 2, built.length
    end

    def test_factory_does_not_mutate_the_global_store
      ::Fixtury.define do
        fixture("dependency") { "dep" }
        fixture("record", deps: "dependency") { |deps| "record built with #{deps.dependency}" }
      end

      ::Fixtury.factory("record")

      assert_equal true, ::Fixtury.store.references.empty?
    end

    def test_factory_builds_dependencies_fresh_by_default
      built = []
      ::Fixtury.define do
        fixture("dependency") do
          built << :dependency
          "dep"
        end
        fixture("record", deps: "dependency") { |deps| deps.dependency }
      end

      ::Fixtury.factory("record")
      ::Fixtury.factory("record")

      assert_equal 2, built.length
    end

    def test_factory_builds_shared_dependencies_once_per_invocation
      built = []
      ::Fixtury.define do
        fixture("dependency") do
          built << :dependency
          "dep"
        end
        fixture("a", deps: "dependency") { |deps| deps.dependency }
        fixture("record", deps: %w[a dependency]) { |deps| "#{deps.a} #{deps.dependency}" }
      end

      ::Fixtury.factory("record")

      assert_equal 1, built.length
    end

    def test_factory_with_a_dedicated_store_reuses_dependencies_across_invocations
      built = []
      ::Fixtury.define do
        fixture("dependency") do
          built << :dependency
          "dep"
        end
        fixture("record", deps: "dependency") do |deps|
          value = deps.dependency
          built << :record
          value
        end
      end

      ::Fixtury.factory("record", store: :my_cache)
      ::Fixtury.factory("record", store: :my_cache)

      # The dependency is cached in the dedicated store while the target is built every time.
      assert_equal [:dependency, :record, :record], built
      assert_equal true, ::Fixtury.store.references.empty?
      assert_equal %w[/dependency], ::Fixtury.store(:my_cache).references.keys
    end

    def test_factory_requires_a_definition
      ::Fixtury.define do
        namespace "things" do
          fixture("record") { "record" }
        end
      end

      assert_raises ArgumentError do
        ::Fixtury.factory("things")
      end
    end

    def test_named_stores_bootstrap_from_their_own_file
      Dir.mktmpdir do |dir|
        ::Fixtury.configuration.filepath = File.join(dir, "fixtury.yml")

        ref = ::Fixtury::Reference.new("/dependency", "some-locator-key")
        File.binwrite(
          File.join(dir, "fixtury.my_cache.yml"),
          { references: { "/dependency" => ref } }.to_yaml
        )

        store = ::Fixtury::Store.new(name: :my_cache)
        assert_equal %w[/dependency], store.references.keys
        assert_equal "some-locator-key", store.references["/dependency"].locator_key

        # The default store should not pick up the named store's references.
        assert_equal true, ::Fixtury::Store.new.references.empty?
      end
    end

    def test_dump_file_writes_each_named_store_to_its_own_file
      Dir.mktmpdir do |dir|
        ::Fixtury.configuration.filepath = File.join(dir, "fixtury.yml")

        ::Fixtury.define do
          fixture("dependency") { "dep" }
          fixture("record", deps: "dependency") { |deps| deps.dependency }
        end

        ::Fixtury.factory("record", store: :my_cache)
        ::Fixtury.configuration.dump_file

        assert_equal true, File.file?(File.join(dir, "fixtury.yml"))
        assert_equal true, File.file?(File.join(dir, "fixtury.my_cache.yml"))

        references = ::Fixtury.configuration.stored_references(:my_cache)
        assert_equal %w[/dependency], references.keys

        ::Fixtury.configuration.reset
        assert_equal false, File.file?(File.join(dir, "fixtury.yml"))
        assert_equal false, File.file?(File.join(dir, "fixtury.my_cache.yml"))
      end
    end

    def test_reset_deletes_named_store_files_even_when_stores_are_not_instantiated
      Dir.mktmpdir do |dir|
        ::Fixtury.configuration.filepath = File.join(dir, "fixtury.yml")
        File.binwrite(File.join(dir, "fixtury.yml"), { references: {} }.to_yaml)
        File.binwrite(File.join(dir, "fixtury.my_cache.yml"), { references: {} }.to_yaml)

        assert_equal true, ::Fixtury.stores.empty?
        ::Fixtury.configuration.reset

        assert_equal false, File.file?(File.join(dir, "fixtury.yml"))
        assert_equal false, File.file?(File.join(dir, "fixtury.my_cache.yml"))
      end
    end

    def test_store_filepath_embeds_the_store_name
      ::Fixtury.configuration.filepath = "tmp/fixtury.yml"

      assert_equal "tmp/fixtury.yml", ::Fixtury.configuration.store_filepath
      assert_equal "tmp/fixtury.yml", ::Fixtury.configuration.store_filepath(:default)
      assert_equal "tmp/fixtury.my_cache.yml", ::Fixtury.configuration.store_filepath(:my_cache)
    end

  end
end
