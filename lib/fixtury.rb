# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/module/delegation"
require "fixtury/version"
require "fixtury/schema"
require "fixtury/locator"
require "fixtury/store"
# require 'debug'

# Top level namespace of the gem
module Fixtury

  LOG_LEVELS = {
    (LOG_LEVEL_NONE = :none) => 0,
    (LOG_LEVEL_INFO = :info) => 1,
    (LOG_LEVEL_DEBUG = :debug) => 2,
    (LOG_LEVEL_ALL = :all) => 3,
  }.freeze

  DEFAULT_LOG_LEVEL = LOG_LEVEL_INFO

  attr_accessor :log_level

  # Shortcut for opening the top level schema.
  def self.define(&block)
    schema.define(&block)
    schema
  end

  # The default top level schema. Fixtury::Schema instances can be completely self-contained but most
  # usage would be through this shared definition.
  def self.schema
    @schema ||= ::Fixtury::Schema.new(parent: nil, name: "")
  end

  def self.log_level
    @log_level ||= set_log_level
  end

  def self.log(text = nil, level: LOG_LEVEL_DEBUG, name: nil, newline: true)
    return if log_level == LOG_LEVEL_NONE

    message_level = LOG_LEVELS.fetch(level) { LOG_LEVEL_DEBUG }
    return unless LOG_LEVELS[log_level] >= message_level

    msg = +"[fixtury"
    msg << "|#{name}" if name
    msg << "]"
    msg << " #{text}" if text
    msg << " #{yield}" if block_given?
    msg << "\n" if newline

    print msg
    msg
  end

  def self.set_log_level
    return DEFAULT_LOG_LEVEL if ENV["FIXTURY_LOG_LEVEL"].blank?

    env_level = ENV["FIXTURY_LOG_LEVEL"].to_s.to_sym

    LOG_LEVELS.key?(env_level) ? env_level : DEFAULT_LOG_LEVEL
  end

end

require "fixtury/railtie" if defined?(Rails)
