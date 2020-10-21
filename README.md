# Fixtury

Fixtury aims to provide an interface for creating, managing, and accessing test data in a simple and efficient way. It has no opinion on how you generate the data, it simply provides efficient ways to access it.

Often, fixture frameworks require you to either heavily maintain static fixtures or generate all your fixtures at runtime. Fixtury attempts to find a middle ground that enables a faster and more effecient development process.

For example, if a developer is running a test locally in their development environment there's no reason to build all fixtures for your suite of 30k tests. Instead, if we're able to track the fixture dependencies of the tests that are running we can build (and cache) the data relevant for the specific tests that are run.

```ruby
class MyTest < ::ActiveSupport::TestCase
  include ::Fixtury::TestHooks

  fixtury "users.fresh"
  let(:user) { fixtury("users.fresh") }

  def test_whatever
    assert_eq "Doug", user.first_name
  end

end
```

Loading this file would ensure `users.fresh` is loaded into the fixture set before the suite is run. In the context of ActiveSupport::TestCase, the Fixtury::Hooks file will ensure the database records are present prior to your suite running. Setting `use_transactional_fixtures` ensures all records are rolled back prior to running another test.

In a CI environment, we'd likely want to preload all fixtures. This can be done by requiring all the test files, then telling the fixtury store to load all definitions.
