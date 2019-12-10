# Fixtury

The goal of this library is to provide an interface for accessing fixture data on-demand rather than having to build it all up front. By centralizing and wrapping the definitions of data generation, we can preload and optimize how we load data.

For example, if a developer is running a test locally, there's no reason to build all fixtures.

```
class MyTest < ::Test

  fixtury "users.fresh"
  let(:user) { fixtury["users.fresh"] }

  def test_whatever
    assert_eq "Doug", user.first_name
  end

end

```

Loading this file would ensure `users.fresh` is loaded into the DB before the suite is run.

However, if we're in a CI environment. We'd just require all the test files, tell fixtures to load, and essentially preload all requirements.
