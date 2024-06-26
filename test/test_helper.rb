# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fixtury"

require "byebug"
require "minitest/autorun"
require "support/db/helpers"

class Test < Minitest::Test

  extend ::Minitest::Spec::DSL # for let
  extend ::Support::Db::Helpers

  def before_setup
    ::Fixtury.schema.reset
    ::Fixtury.store.reset
    super
  end

  def load_default_fixtures
    load "support/fixtures.rb"
  end

end

::Minitest::Runnable.runnables.delete Test

require "mocha/minitest"
