# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/array/extract_options"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/acts_like"
require "active_support/core_ext/object/blank"

require "fixtury/version"

require "fixtury/definition_executor"
require "fixtury/dependency"
require "fixtury/dependency_store"
require "fixtury/errors"
require "fixtury/hooks"
require "fixtury/locator"
require "fixtury/path_resolver"
require "fixtury/reference"
require "fixtury/store"

require "fixtury/schema_node"
require "fixtury/definition"
require "fixtury/schema"


# Top level namespace of the gem. The accessors provided on the Fixtury namespace are meant to be shared
# across the entire application. The Fixtury::Schema instance is the primary interface for defining and
# accessing fixtures and can be accessed via Fixtury.schema.
module Fixtury

  LOG_LEVELS = {
    (LOG_LEVEL_NONE = :none) => 0,
    (LOG_LEVEL_INFO = :info) => 1,
    (LOG_LEVEL_DEBUG = :debug) => 2,
    (LOG_LEVEL_ALL = :all) => 3,
  }.freeze

  DEFAULT_LOG_LEVEL = LOG_LEVEL_INFO

  # Shortcut for opening the top level schema.
  def self.define(&block)
    schema.define(&block)
    schema
  end

  # Global hooks accessor. Fixtury will call these hooks at various points in the lifecycle of a fixture or setup.
  def self.hooks
    @hooks ||= ::Fixtury::Hooks.new
  end

  # The default top level schema. Fixtury::Schema instances can be completely self-contained but most
  # usage would be through this shared definition.
  def self.schema
    @schema ||= ::Fixtury::Schema.new
  end

  def self.schema=(schema)
    @schema = schema
  end

  # Default store for fixtures. This is a shared store that can be used across the application.
  def self.store
    @store ||= ::Fixtury::Store.new(schema: schema)
  end

  def self.store=(store)
    @store = store
  end

  def self.log_level
    return @log_level if @log_level

    @log_level = ENV["FIXTURY_LOG_LEVEL"]
    @log_level ||= DEFAULT_LOG_LEVEL
    @log_level = @log_level.to_s.to_sym
    @log_level
  end

  def self.log(text = nil, level: LOG_LEVEL_DEBUG, name: nil, newline: true)
    desired_level = LOG_LEVELS.fetch(log_level) { DEFAULT_LOG_LEVEL }
    return if desired_level == LOG_LEVEL_NONE

    message_level = LOG_LEVELS.fetch(level) { LOG_LEVEL_DEBUG }
    return unless desired_level >= message_level

    msg = +"[fixtury"
    msg << "|#{name}" if name
    msg << "]"
    msg << " #{text}" if text
    msg << " #{yield}" if block_given?
    msg << "\n" if newline

    print msg
    msg
  end

end

require "fixtury/railtie" if defined?(Rails)
