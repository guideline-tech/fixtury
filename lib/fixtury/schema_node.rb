module Fixtury
  module SchemaNode

    extend ActiveSupport::Concern

    VALID_NODE_NAME = /^[a-z0-9_]*$/

    included do
      attr_reader :name, :pathname, :parent, :children, :options
    end

    def initialize(name:, parent: nil, **options)
      name = name.to_s
      raise ArgumentError, "#{name.inspect} is an invalid node name" unless name.match?(VALID_NODE_NAME)

      @name = name
      @parent = parent
      @pathname = [parent&.pathname || "/", @name].compact.join("/").gsub(%r{/+}, "/")
      @children = {}
      @options = {}
      apply_options!(options)
      @parent.add_child(self) if @parent
    end

    def schema_node_type
      raise NotImplementedError
    end

    def acts_like_fixtury_schema_node?
      true
    end

    def first_ancestor
      first_ancestor? ? self : parent.first_ancestor
    end

    def add_child(child)
      if children.key?(child.name) && children[child.name] != child
        raise Errors::AlreadyDefinedError, child.pathname
      end

      children[child.name] = child
    end

    def first_ancestor?
      parent.nil?
    end

    def isolation_key(default: true)
      from_parent = parent&.isolation_key(default: nil)
      return from_parent if from_parent

      value = options[:isolate] || default
      value = (value == true ? pathname : value&.to_s).presence
      value == "/" ? nil : value # special case to accommodate root nodes
    end

    def get!(search)
      thing = get(search)
      raise Errors::SchemaNodeNotDefinedError, search unless thing

      thing
    end

    def get(search)
      raise ArgumentError, "`search` must be provided" if search.blank?

      resolver = Fixtury::PathResolver.new(namespace: self.pathname, search: search)
      resolver.possible_absolute_paths.each do |path|
        target = first_ancestor
        segments = path.split("/")
        segments.reject!(&:blank?)
        segments.shift if segments.first == target.name
        segments.each do |segment|
          target = target.children[segment]
          break unless target
        end

        return target if target
      end

      nil
    end
    alias [] get

    # helpful for inspection
    def structure(prefix = "")
      out = []
      my_structure = +"#{prefix}#{schema_node_type}:#{name}"
      my_structure << "(#{options.inspect})" if options.present?
      out << my_structure
      children.each_value do |child|
        out << child.structure("#{prefix}  ")
      end
      out.join("\n")
    end

    def apply_options!(opts = {})
      opts.each do |key, value|
        if options.key?(key) && options[key] != value
          raise Errors::OptionCollisionError.new(name, key, options[key], value)
        end

        options[key] = value
      end
    end

  end
end
