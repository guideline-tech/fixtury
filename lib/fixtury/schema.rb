# frozen_string_literal: true

module Fixtury
  class Schema

    attr_reader :definitions, :children, :name, :parent, :relative_name, :options

    def initialize(parent:, name:)
      @name = name
      @parent = parent
      @relative_name = @name.split("/").last
      @options = {}
      @frozen = false
      reset!
    end

    def merge_options(opts = {})
      opts.each_pair do |k, v|
        if options.key?(k) && options[k] != v
          raise Errors::OptionCollisionError.new(name, k, options[k], v)
        end

        options[k] = v
      end
    end

    def inheritable_definition_options
      out = {}

      case options[:isolate]
      when true
        out[:isolation_key] = name
      when String, Symbol
        out[:isolation_key] = options[:isolate].to_s
      end

      out
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

    def get_definition!(name)
      dfn = get_definition(name)
      raise Errors::FixtureNotDefinedError, name unless dfn

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
      options = inheritable_definition_options.merge(options)
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
        raise Errors::AlreadyDefinedError, definition.name if definition
      end

      if namespaces
        ns = find_child_schema(name: name)
        raise Errors::AlreadyDefinedError, ns.name if ns
      end
    end

    def ensure_not_frozen!
      return unless frozen?

      raise Errors::SchemaFrozenError
    end

  end
end
