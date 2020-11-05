# frozen_string_literal: true

require "fixtury/definition"
require "fixtury/path"
require "fixtury/errors/already_defined_error"
require "fixtury/errors/fixture_not_defined_error"
require "fixtury/errors/schema_frozen_error"
require "fixtury/errors/option_collision_error"

module Fixtury
  class Schema

    attr_reader :definitions, :children, :name, :parent, :relative_name, :around_fixture_definition, :options

    def initialize(parent:, name:)
      @name = name
      @parent = parent
      @relative_name = @name.split("/").last
      @around_fixture_definition = nil
      @options = {}
      @frozen = false
      reset!
    end

    def merge_options(opts = {})
      opts.each_pair do |k, v|
        if options.key?(k) && options[k] != v
          raise ::Fixtury::Errors::OptionCollisionError.new(name, k, options[k], v)
        end

        options[k] = v
      end
    end

    def around_fixture(&block)
      @around_fixture_definition = block
    end

    def around_fixture_hook(executor, &definition)
      maybe_invoke_parent_around_fixture_hook(executor) do
        if around_fixture_definition.nil?
          yield
        else
          around_fixture_definition.call(executor, definition)
        end
      end
    end

    def maybe_invoke_parent_around_fixture_hook(executor, &block)
      return yield unless parent

      parent.around_fixture_hook(executor, &block)
    end

    def reset!
      @children = {}
      @definitions = {}
    end

    def freeze!
      @frozen = true
    end

    def frozen?
      !!@frozen
    end

    def top_level_schema
      top_level_schema? ? self : parent.top_level_schema
    end

    def top_level_schema?
      parent.nil?
    end

    def define(&block)
      ensure_not_frozen!
      instance_eval(&block)
      self
    end

    # helpful for inspection
    def structure(indent = "")
      out = []
      out << "#{indent}ns:#{relative_name}"
      definitions.keys.sort.each do |key|
        out << "#{indent}  defn:#{key}"
      end

      children.keys.sort.each do |key|
        child = children[key]
        out << child.structure("#{indent}  ")
      end

      out.join("\n")
    end

    def namespace(name, options = {}, &block)
      ensure_not_frozen!
      ensure_no_conflict!(name: name, definitions: true, namespaces: false)

      child = find_or_create_child_schema(name: name, options: options)
      child.instance_eval(&block) if block_given?
      child
    end

    def fixture(name, options = {}, &block)
      ensure_not_frozen!
      ensure_no_conflict!(name: name, definitions: true, namespaces: true)
      create_child_definition(name: name, options: options, &block)
    end

    def enhance(name, &block)
      ensure_not_frozen!
      definition = get_definition!(name)
      definition.enhance(&block)
      definition
    end

    def merge(other_ns)
      ensure_not_frozen!
      other_ns.definitions.each_pair do |name, dfn|
        fixture(name, dfn.options, &dfn.callable)
        dfn.enhancements.each do |e|
          enhance(name, &e)
        end
      end

      other_ns.children.each_pair do |name, other_ns_child|
        namespace(name, other_ns_child.options) do
          merge(other_ns_child)
        end
      end

      around_fixture(&other_ns.around_fixture_definition) if other_ns.around_fixture_definition

      self
    end

    def get_definition!(name)
      dfn = get_definition(name)
      raise ::Fixtury::Errors::FixtureNotDefinedError, name unless dfn

      dfn
    end

    def get_definition(name)
      path = ::Fixtury::Path.new(namespace: self.name, path: name)
      top_level = top_level_schema

      dfn = nil
      path.possible_absolute_paths.each do |abs_path|
        *namespaces, definition_name = abs_path.split("/")

        namespaces.shift if namespaces.first == top_level.name
        target = top_level

        namespaces.each do |ns|
          next if ns.empty?

          target = target.children[ns]
          break unless target
        end

        dfn = target.definitions[definition_name] if target
        return dfn if dfn
      end

      nil
    end

    def get_namespace(name)
      path = ::Fixtury::Path.new(namespace: self.name, path: name)
      top_level = top_level_schema

      path.possible_absolute_paths.each do |abs_path|
        *namespaces, _definition_name = abs_path.split("/")

        namespaces.shift if namespaces.first == top_level.name
        target = top_level

        namespaces.each do |ns|
          next if ns.empty?

          target = target.children[ns]
          break unless target
        end

        return target if target
      end

      nil
    end

    protected

    def find_child_schema(name:)
      children[name.to_s]
    end

    def find_or_create_child_schema(name:, options:)
      name = name.to_s
      child = find_child_schema(name: name)
      child ||= begin
        children[name] = begin
          child_name = build_child_name(name: name)
          self.class.new(name: child_name, parent: self)
        end
      end
      child.merge_options(options)
      child
    end

    def find_child_definition(name:)
      definitions[name.to_s]
    end

    def create_child_definition(name:, options:, &block)
      child_name = build_child_name(name: name)
      definition = ::Fixtury::Definition.new(name: child_name, schema: self, options: options, &block)
      definitions[name.to_s] = definition
    end

    def build_child_name(name:)
      name = name&.to_s
      raise ArgumentError, "`name` must be provided" if name.nil?
      raise ArgumentError, "#{name} is invalid. `name` must contain only a-z, A-Z, 0-9, and _." unless /^[a-zA-Z_0-9]+$/.match?(name)

      arr = ["", self.name, name]
      arr.join("/").gsub(%r{/{2,}}, "/")
    end

    def ensure_no_conflict!(name:, namespaces:, definitions:)
      if definitions
        definition = find_child_definition(name: name)
        raise ::Fixtury::Errors::AlreadyDefinedError, definition.name if definition
      end

      if namespaces
        ns = find_child_schema(name: name)
        raise ::Fixtury::Errors::AlreadyDefinedError, ns.name if ns
      end
    end

    def ensure_not_frozen!
      return unless frozen?

      raise ::Fixtury::Errors::SchemaFrozenError
    end

  end
end
