# Fixtury

The goal of this library is to provide an interface for accessing fixture data on-demand rather than having to manage all resources up front. By centralizing and wrapping the definitions of data generation, we can preload and optimize how we load data, yet allow deferred behaviors when desired.

For example, if a developer is running a test locally, there's no reason to build all fixtures for your suite.

```
class MyTest < ::Test

  fixtury "users.fresh"
  let(:user) { fixtury("users.fresh") }

  def test_whatever
    assert_eq "Doug", user.first_name
  end

end

```

Loading this file would ensure `users.fresh` is loaded into the fixture set before the suite is run. In the context of ActiveSupport::TestCase, the Fixtury::Hooks file will ensure the database records are present prior to your suite running. Setting `use_transactional_fixtures` ensures all records are rolled back prior to running another test.

In a CI environment, we'd likely want to preload all fixtures. This can be done by requiring all the test files, then telling the fixtury store to load all definitions.
