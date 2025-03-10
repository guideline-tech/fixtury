# frozen_string_literal: true

require "fixtury"
require "active_support/core_ext/class/attribute"

module Fixtury
  # MinitestHooks is a module designed to hook into a Minitest test case, and
  # provide a way to load fixtures into the test case. It is designed to be
  # prepended into the test case class, and will automatically load fixtures
  # before the test case is setup.
  #
  # The module also provides a way to define fixture dependencies, and will
  # automatically load those dependencies before the test case is setup.
  #
  # @example
  #   class MyTest < Minitest::Test
  #     prepend Fixtury::MinitestHooks
  #
  #     fixtury "user"
  #     fixtury "post"
  #
  #     def test_something
  #       user # => returns the `users` fixture
  #       user.do_some_mutation
  #       assert_equal 1, user.mutations.count
  #     end
  #   end
  #
  #   # In the above example, the `users` and `posts` fixtures will be loaded
  #   # before the test case is setup, and any changes will be rolled back
  #   # after the test case is torn down.
  #
  #   # The `fixtury` method also accepts a `:as` option, which can be used to
  #   # define a named accessor method for a fixture. This is useful when
  #   # defining a single fixture, and you want to access it using a different
  #   # name. If no `:as` option is provided, the fixture will be accessed
  #   # using the last segment of the fixture's pathname.
  #
  #   class MyTest < Minitest::Test
  #     prepend Fixtury::MinitestHooks
  #
  #     fixtury "/my/user_record", as: :user
  #
  #   end
  #
  # Use `as: false` if you do not want an accessor created.
  #
  # A Set object named fixtury_dependencies is made available on the test class.
  # This allows you to load all Minitest runnables and analyze what fixtures are
  # needed. This is very helpful in CI pipelines when you want to prepare all fixtures
  # ahead of time to share between multiple processes.
  #
  # It is the responsibility of the suite to manage the snapshot or rollback of the database. Generally
  # something like ActiveRecord's use_transactional_fixtures will work just fine.
  module MinitestHooks

    def self.prepended(klass)
      klass.class_attribute :fixtury_dependencies
      klass.fixtury_dependencies = Set.new
      klass.extend ClassMethods
    end

    def self.included(klass)
      raise ArgumentError, "#{name} should be prepended, not included"
    end

    module ClassMethods

      # Declare fixtury dependencies for this test case. This will automatically
      # load the fixtures before the test case is setup.
      #
      # @param searches [Array<String>] A list of fixture names to load. These should be resolvable paths relative to Fixtury.schema (root).
      # @param opts [Hash] A list of options to customize the behavior of the fixtures.
      #   @option opts [Symbol, String, Boolean] :as (true) The name of the accessor method to define for the fixture. If true (default), the last segment will be used.
      # @return [void]
      def fixtury(*searches, **opts)
        pathnames = searches.map do |search|
          dfn = Fixtury.schema.get!(search)
          dfn.pathname
        end

        self.fixtury_dependencies += pathnames

        accessor_option = opts[:as]
        accessor_option = opts[:accessor] if accessor_option.nil? # old version, backwards compatability
        accessor_option = accessor_option.nil? ? true : accessor_option

        if accessor_option

          if accessor_option != true && pathnames.length > 1
            raise ArgumentError, "A named :as option is only available when providing one fixture"
          end

          pathnames.each do |pathname|
            method_name = (accessor_option == true ? pathname.split("/").last : accessor_option).to_sym
            ivar = :"@fixtury_#{method_name}"

            class_eval <<-EV, __FILE__, __LINE__ + 1
              def #{method_name}
                return #{ivar} if defined?(#{ivar})

                #{ivar} = fixtury("#{pathname}")
              end
            EV
          end
        end
      end

    end

    # Minitest before_setup hook. This will load the fixtures before the test.
    def before_setup(...)
      fixtury_setup if fixtury_dependencies.any?
      super
    end

    # Access a fixture via a search term. This will access the fixture from the Fixtury store.
    # If the fixture was not declared as a dependency, an error will be raised.
    #
    # @param search [String] The search term to use to find the fixture.
    # @return [Object] The fixture.
    # @raise [Fixtury::Errors::UnknownTestDependencyError] if the search term does not result in a declared dependency.
    # @raise [Fixtury::Errors::SchemaNodeNotDefinedError] if the search term does not result in a recognized fixture.
    def fixtury(search)
      dfn = Fixtury.schema.get!(search)

      unless fixtury_dependencies.include?(dfn.pathname)
        raise Errors::UnknownTestDependencyError, "Unrecognized fixtury dependency `#{dfn.pathname}` for #{self.class}"
      end

      Fixtury.store.get(dfn.pathname)
    end

    # Load all dependenct fixtures and begin a transaction for each database connection.
    def fixtury_setup
      Fixtury.store.clear_stale_references!
      fixtury_load_all_fixtures!
    end

    # Load all fixture dependencies that have not previously been loaded into the store.
    #
    # @return [void]
    def fixtury_load_all_fixtures!
      fixtury_dependencies.each do |name|
        next if Fixtury.store.loaded?(name)

        ::Fixtury.log("preloading #{name.inspect}", name: "test", level: ::Fixtury::LOG_LEVEL_INFO)
        fixtury(name)
      end
    end

  end
end
