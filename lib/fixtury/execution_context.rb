# frozen_string_literal: true

# a class made available so helper methods can be provided within the fixture dsl
module Fixtury
  class ExecutionContext

    def before_fixture(_dfn); end

    def around_fixture(_dfn)
      yield
    end

    def after_fixture(_dfn, _value); end

  end
end
