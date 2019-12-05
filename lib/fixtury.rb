# frozen_string_literal: true

require "fixtury/version"
require "fixtury/config"

module Fixtury

  # Your code goes here...

  def self.config
    ::Fixture::Config.instance
  end

end
