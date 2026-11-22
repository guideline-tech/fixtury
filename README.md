# Fixtury

Fixtury aims to provide an interface for creating, managing, and accessing test data in a simple and on-demand way. It has no opinion on how you generate the data, it simply provides efficient ways to access it.

Often, fixture frameworks require you to either heavily maintain static fixtures or generate all your fixtures at runtime. Fixtury attempts to find a middle ground that enables a faster and more effecient development process while allowing you to generate realistic test data.

For example, if a developer is running a test locally in their development environment there's no reason to build all fixtures for your suite of 30k tests. Instead, if we're able to track the fixture dependencies of the tests that are running we can build (and cache) the data relevant for the specific tests that are run.

```ruby
require "fixtury/minitest_hooks"

class MyTest < ::Minitest::Test
  prepend ::Fixtury::MintestHooks

  fixtury "users/fresh", as: :user

  def test_whatever
    assert_eq "Doug", user.first_name
  end

end
```

Loading this file would ensure `users/fresh` is loaded into the fixture set before the suite is run. In the context of Minitest::Test, the Fixtury::MinitestHooks file will ensure the fixtures are present prior to your suite running.

## Configuration

If you're using Rails, you can `require "fixtury/railtie"` to accomplish a standard installation which will observe common rails files for changes and expects fixture definitions to defined in `test/fixtures`. See the railtie class for details.

For non-rails environments or additional configuration, you can open up the Fixtury configuration like so:
```ruby
::Fixtury.configure do |config|
  config.locator_backend = :global_id # the locator behavior to use for finding fixtures
  config.filepath = File.join(root, "tmp/fixtury.yml") # the location to dump the fixtury references
  config.add_fixture_path = File.join(root, "fixtures/**/*.rb")
  config.add_dependency_path = File.join(root, "db/schema.rb")
end
```
See Fixtury::Configuration for all options.

When your Fixtury is configured, you should call `Fixtury.start`.

For minitest integration, you should dump the configuration file after the suite runs or after your fixture dependencies are built:

```ruby
::Minitest.after_run do
  ::Fixtury.configuration.dump_file
end
```

In a CI environment, we'd likely want to preload all fixtures to produce a database snapshot to be shared. This can be done by configuring Fixtury, calling `Fixtury.start`, then calling `Fixtury.load_all_fixtures`. All fixtures declared in the configuration's fixture_paths will be loaded.

## Defining Fixtures

There are two primary principals in Fixtury: namespaces and fixture definitions. See below for an example of how they're used.

```ruby
Fixtury.define do

  fixture "user" do
    User.create(...)
  end

  namespace "addresses" do
    fixture "sample" do
      Address.create(...)
    end
  end

  namespace "user_with_address" do
    fixture "user", deps: "address" do |deps|
      User.create(address_id: deps.address.id, ...)
    end

    fixture "address" do
      Address.create(...)
    end
  end
end
```

As you can see fixtures are named in a nested structure and can refer to each other via dependencies. See Fixtury::Dependency for more specifics.

## Factory Mode

Fixture definitions can also be used as factories. `Fixtury.factory` invokes the definition every time it's called and never stores the result, making it useful for generating new records on demand without mutating the global cache.

```ruby
user_a = Fixtury.factory("users/fresh")
user_b = Fixtury.factory("users/fresh")
user_a == user_b # => false, each call builds a new record
```

By default, dependencies of the definition are resolved through an ephemeral store: they are built fresh for the invocation and discarded afterwards. Within a single invocation a shared dependency is only built once.

If the dependency tree is expensive to build, a dedicated store can be used instead:

```ruby
Fixtury.factory("users/fresh", store: :my_cache)
```

Dependencies will be resolved through (and cached in) a dedicated store named `:my_cache`, shared across factory invocations using the same store name. The named store is bootstrapped from its own file, derived from the configured filepath — e.g. `tmp/fixtury.yml` produces `tmp/fixtury.my_cache.yml` — and is persisted alongside the default store when `Fixtury.configuration.dump_file` is called. In all cases the target definition itself is always invoked and its result is never stored.

## Isolation Levels

Isolation keys enable groups of fixtures to use and modify the same resources. When one fixture from an isolation level is built, all fixtures in that isolation level are built. This allows multiple fixtures to potentially mutate a resource while keeping the definition consistent.

```ruby
Fixtury.define do
  namespace "use_cases" do
    namespace "onboarded", isolate: true do

      fixture "user" do
        User.create(...)
      end

      fixture "profile", deps: "user" do |deps|
        profile = Profile.create(user: deps.user, ...)
        user.update(profiles_count: 1, onboarded_at: Time.current)
        profile
      end

    end
  end
end
```

### ActiveRecord Integration

When installed with the railtie, a MutationObserver module is prepended into ActiveRecord::Base. It observes record mutations and ensures a record is not mutated outside of the declared isolation level. If you're not using ActiveRecord check out Fixtury::MutationObserver to see how you could hook into other frameworks.

In your test suite when utilizing the Fixtury::MinitestHooks records will be loaded before ActiveRecord's transactional fixtures transaction is opened. This means the you can define all your fixtures in your tests, they will be prebuilt and, as long as the fixtury references are preserved, all your fixtures are cached across runs. The fixtures in each file are loaded on demand which means only the fixtures necessary for the test to run are prebuilt (and cached for reuse). Standard transactional fixture rollback occurs after each test run so any mutation to fixtures will not be persisted.

