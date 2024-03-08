# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fixtury"

require "byebug"
require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

class Test < Minitest::Test

  extend ::Minitest::Spec::DSL # for let

  def before_setup
    ::Fixtury.schema.reset!
    ::Fixtury.store = ::Fixtury::Store.new
    super
  end

end

::Minitest::Runnable.runnables.delete Test

require "mocha/minitest"
