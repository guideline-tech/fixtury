# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/array/extract_options"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/acts_like"
require "active_support/core_ext/object/blank"

require "fixtury/version"

require "fixtury/configuration"
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

  def self.configuration
    @configuration ||= ::Fixtury::Configuration.new
    yield @configuration if block_given?
    @configuration
  end

  def self.configure(&block)
    self.configuration(&block)
  end


  # Shortcut for opening the top level schema.
  def self.define(&block)
    schema.define(&block)
    schema
  end

  # Global hooks accessor. Fixtury will call these hooks at various points in the lifecycle of a fixture or setup.
  def self.hooks
    @hooks ||= ::Fixtury::Hooks.new
  end

  def self.now
    hooks.call(:time_access) do
      ::Time.now
    end
  end

  # The default top level schema. Fixtury::Schema instances can be completely self-contained but most
  # usage would be through this shared definition.
  def self.schema
    @schema ||= ::Fixtury::Schema.new
  end

  # Default store for fixtures. This is a shared store that can be used across the application.
  # A name can be provided to access a dedicated store instead. Named stores behave just like
  # the default store but are bootstrapped from (and dumped to) their own file. e.g. a name of
  # :my_cache would utilize a fixtury.my_cache.yml file alongside the default fixtury.yml.
  #
  # @param name [Symbol, String] The name of the store to access.
  # @return [Fixtury::Store] The store associated with the given name.
  def self.store(name = :default)
    name = name.to_sym
    stores[name] ||= ::Fixtury::Store.new(name: name)
  end

  # All shared stores that have been instantiated, keyed by name.
  #
  # @return [Hash<Symbol, Fixtury::Store>]
  def self.stores
    @stores ||= {}
  end

  # Invoke a definition without caching the result. The definition is executed every time,
  # making this useful for generating new records on demand without mutating the global cache.
  #
  # By default the definition's dependencies are resolved through an ephemeral store, meaning
  # they are built fresh and discarded afterwards. If a store name is provided, dependencies
  # are resolved through (and cached in) the named store instead, which is bootstrapped from
  # its own file. e.g. factory("some/definition", store: :my_cache) would resolve dependencies
  # via a store backed by fixtury.my_cache.yml. In both cases the definition itself is always
  # invoked and its result is never stored.
  #
  # @param search [String] The name of the definition to invoke.
  # @param store [Symbol, String, nil] The name of a dedicated store to resolve dependencies through.
  # @return [Object] The newly built value.
  # @raise [ArgumentError] if the search does not refer to a definition.
  def self.factory(search, store: nil)
    dfn = schema.get!(search)
    raise ArgumentError, "#{search.inspect} must refer to a definition" unless dfn.acts_like?(:fixtury_definition)

    factory_store = store ? self.store(store) : ::Fixtury::Store.new(name: nil)
    ::Fixtury::DefinitionExecutor.new(store: factory_store, definition: dfn).call.value
  end

  # Load all known fixture files configured in Configuration. Reset the store references if
  # a dependency file has changed.
  def self.start
    load_all_schemas
    reset_if_changed
  end

  # Require each schema file to ensure that all definitions are loaded.
  def self.load_all_schemas(mechanism = :require)
    configuration.fixture_files.each do |filepath|
      if mechanism == :require
        require filepath
      elsif mechanism == :load
        load filepath
      else
        raise ArgumentError, "unknown load mechanism: #{mechanism}"
      end
    end
  end

  # Ensure all definitions are loaded and then load all known fixtures.
  def self.load_all_fixtures(...)
    load_all_schemas(...)
    store.load_all
  end

  # Remove all references from the active stores and reset the dependency files.
  def self.reset
    configuration.reset
    stores.each_value(&:reset)
  end

  # Perform a reset if any of the tracked files have changed.
  def self.reset_if_changed
    changes = configuration.changes
    if changes
      log("changes found, resetting | #{changes}", level: LOG_LEVEL_INFO)
      reset
    else
      log("no changes, skipping reset", level: LOG_LEVEL_INFO)
    end
  end

  def self.log(text = nil, level: LOG_LEVEL_DEBUG, name: nil, newline: true)
    desired_level = LOG_LEVELS.fetch(configuration.log_level) { DEFAULT_LOG_LEVEL }
    return if desired_level == LOG_LEVEL_NONE

    message_level = LOG_LEVELS.fetch(level) { LOG_LEVEL_DEBUG }
    return unless desired_level >= message_level

    msg = +"[fixtury"
    msg << "|#{name}" if name
    msg << "]"
    msg << " #{text}" if text
    msg << " #{yield}" if block_given?
    msg << "\n" if newline

    # TODO: logger
    print msg
    msg
  end

end

require "fixtury/railtie" if defined?(Rails)
