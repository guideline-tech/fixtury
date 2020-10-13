# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "fixtury"

require "byebug"
require "minitest/autorun"
require "minitest/reporters"

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

class Test < Minitest::Test

  extend ::MiniTest::Spec::DSL # for let

  def before_setup
    ::Fixtury.schema.reset!
    super
  end

end

::MiniTest::Runnable.runnables.delete Test

require "mocha/minitest"
