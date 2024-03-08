# frozen_string_literal: true

module Fixtury
  class Schema

    attr_reader :definitions, :children, :name, :parent, :relative_name, :options

    def initialize(parent: nil, name: "", **options)
      @name = name
      @parent = parent
      @relative_name = @name.split("/").last
      @children = {}
      @definitions = {}
      @options = {}
      apply_options!(options)
    end

    def acts_like_fixtury_schema?
      true
    end

    def top_level_schema
      top_level_schema? ? self : parent.top_level_schema
    end

    def top_level_schema?
      parent.nil?
    end

    def define(&block)
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

    def namespace(relative_name, **options, &block)
      child = find_or_create_child_schema!(relative_name: relative_name, options: options)
      child.instance_eval(&block) if block_given?
      child
    end

    def fixture(relative_name, **options, &block)
      create_child_definition!(relative_name: relative_name, options: options, &block)
    end

    def get!(name)
      thing = get(name)
      raise Errors::FixtureNotDefinedError, name unless thing

      thing
    end

    def get(name)
      raise ArgumentError, "`name` must be provided" if name.nil?

      path = Fixtury::Path.new(namespace: self.name, path: name)
      path.possible_absolute_paths.each do |path|
        ns = top_level_schema
        segments = path.split("/")
        segments.reject!(&:blank?)
        segments.shift if segments.first == ns.name
        *namespaces, target_name = segments

        namespaces.each do |segment|
          ns = ns.children[segment]
          break unless ns
        end

        next unless ns

        return ns.definitions[target_name] if ns.definitions.key?(target_name)
        return ns.children[target_name] if ns.children.key?(target_name)
      end

      nil
    end
    alias [] get

    def apply_options!(opts = {})
      opts = opts.dup
      isolate = opts.delete(:isolate)
      isolate = name if isolate == true
      opts[:isolate] = isolate.to_s if isolate

      opts.each do |key, value|
        if options.key?(key) && options[key] != value
          raise Errors::OptionCollisionError.new(name, key, options[key], value)
        end

        options[key] = value
      end
    end

    protected

    def cascading_options
      out = {}
      out[:isolate] = options[:isolate] if options[:isolate]
      out
    end
    alias cascading_definition_options cascading_options
    alias cascading_namespace_options cascading_options

    def find_or_create_child_schema!(relative_name:, options:)
      child_name = build_child_name(relative_name: relative_name)
      child = get(child_name)

      if child && !child.acts_like?(:fixtury_schema)
        raise Errors::AlreadyDefinedError, child.name
      end

      child ||= self.class.new(name: child_name, parent: self)
      child.apply_options!(options.merge(cascading_namespace_options))
      children[relative_name.to_s] = child
    end

    def create_child_definition!(relative_name:, options:, &block)
      child_name = build_child_name(relative_name: relative_name)
      child = get(child_name)
      raise Errors::AlreadyDefinedError, child.name if child

      definition = ::Fixtury::Definition.new(
        name: child_name,
        schema: self,
        options: options.merge(cascading_definition_options),
        &block
      )
      definitions[relative_name.to_s] = definition
    end

    def build_child_name(relative_name:)
      relative_name = relative_name&.to_s
      raise ArgumentError, "`relative_name` must be provided" if relative_name.nil?
      raise ArgumentError, "#{relative_name} is invalid. `relative_name` must contain only a-z, A-Z, 0-9, and _." unless /^[a-zA-Z_0-9]+$/.match?(relative_name)

      arr = ["", self.name, relative_name]
      arr.join("/").gsub(%r{/{2,}}, "/")
    end

  end
end
