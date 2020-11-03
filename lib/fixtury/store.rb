# frozen_string_literal: true

require "fileutils"
require "singleton"
require "yaml"
require "fixtury/locator"
require "fixtury/errors/circular_dependency_error"
require "fixtury/reference"

module Fixtury
  class Store

    cattr_accessor :instance

    attr_reader :filepath, :references, :ttl, :auto_refresh_expired
    attr_reader :schema, :locator
    attr_reader :log_level

    def initialize(
      filepath: nil,
      locator: ::Fixtury::Locator.instance,
      ttl: nil,
      schema: nil,
      auto_refresh_expired: false
    )
      @schema = schema || ::Fixtury.schema
      @locator = locator
      @filepath = filepath
      @references = @filepath && ::File.file?(@filepath) ? ::YAML.load_file(@filepath) : {}
      @ttl = ttl ? ttl.to_i : ttl
      @auto_refresh_expired = !!auto_refresh_expired
      self.class.instance ||= self
    end

    def dump_to_file
      return unless filepath

      ::FileUtils.mkdir_p(File.dirname(filepath))

      writable = references.each_with_object({}) do |(full_name, ref), h|
        h[full_name] = ref if ref.real?
      end

      ::File.open(filepath, "wb") { |io| io.write(writable.to_yaml) }
    end

    def clear_expired_references!
      return unless ttl

      references.delete_if do |name, ref|
        is_expired = ref_invalid?(ref)
        log("expiring #{name}", level: LOG_LEVEL_DEBUG) if is_expired
        is_expired
      end
    end

    def load_all(schema = self.schema)
      schema.definitions.each_pair do |_key, dfn|
        get(dfn.name)
      end

      schema.children.each_pair do |_key, ns|
        load_all(ns)
      end
    end

    def clear_cache!(pattern: nil)
      pattern ||= "*"
      pattern = "/" + pattern unless pattern.start_with?("/")
      glob = pattern.end_with?("*")
      pattern = pattern[0...-1] if glob
      references.delete_if do |key, _value|
        hit = glob ? key.start_with?(pattern) : key == pattern
        log("clearing #{key}", level: LOG_LEVEL_DEBUG) if hit
        hit
      end
      dump_to_file
    end

    def with_relative_schema(schema)
      prior = @schema
      @schema = schema
      yield
    ensure
      @schema = prior
    end

    def loaded?(name)
      dfn = schema.get_definition!(name)
      full_name = dfn.name
      ref = references[full_name]
      result = ref&.real?
      log(result ? "hit #{full_name}" : "miss #{full_name}", level: LOG_LEVEL_ALL)
      result
    end

    def get(name, execution_context: nil)
      dfn = schema.get_definition!(name)
      full_name = dfn.name
      ref = references[full_name]

      if ref&.holder?
        raise ::Fixtury::Errors::CircularDependencyError, full_name
      end

      if ref && auto_refresh_expired && ref_invalid?(ref)
        log("refreshing #{full_name}", level: LOG_LEVEL_DEBUG)
        clear_ref(full_name)
        ref = nil
      end

      value = nil

      if ref
        log("hit #{full_name}", level: LOG_LEVEL_ALL)
        value = load_ref(ref.value)
        if value.nil?
          clear_ref(full_name)
          log("missing #{full_name}", level: LOG_LEVEL_ALL)
        end
      end

      if value.nil?
        # set the references to a holder value so any recursive behavior ends up hitting a circular dependency error if the same fixture load is attempted
        references[full_name] = ::Fixtury::Reference.holder(full_name)

        value = dfn.call(store: self, execution_context: execution_context)

        log("store #{full_name}", level: LOG_LEVEL_DEBUG)

        ref = dump_ref(full_name, value)
        ref = ::Fixtury::Reference.new(full_name, ref)
        references[full_name] = ref
      end

      value
    end
    alias [] get

    def load_ref(ref)
      locator.load(ref)
    end

    def dump_ref(_name, value)
      locator.dump(value)
    end

    def clear_ref(name)
      references.delete(name)
    end

    def ref_invalid?(ref)
      return true if ttl && ref.created_at < (Time.now.to_i - ttl)

      !locator.recognize?(ref.value)
    end

    def log(msg, level:)
      ::Fixtury.log(msg, level: level, name: "store")
    end

  end
end
