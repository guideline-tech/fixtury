module Fixtury
  # This module is used to provide a common interface for all nodes in the schema tree.
  # Namespaces and fixture definitions adhere to this interface and are provided with
  # common behaviors for registration, traversal, inspection, etc
  module SchemaNode

    extend ActiveSupport::Concern

    VALID_NODE_NAME = /^[a-zA-Z0-9_]*$/

    included do
      attr_reader :name, :pathname, :parent, :first_ancestor, :children, :options
    end

    # Constructs a new SchemaNode object.
    #
    # @param name [String] The relative name of the node.
    # @param parent [Object] The parent node of the node.
    # @param options [Hash] Additional options for the node.
    # @return [Fixtury::SchemaNode] The new SchemaNode object.
    # @raise [ArgumentError] if the name does not match the VALID_NODE_NAME regex.
    def initialize(name:, parent: nil, **options)
      name = name.to_s
      raise ArgumentError, "#{name.inspect} is an invalid node name" unless name.match?(VALID_NODE_NAME)

      @name = name
      @parent = parent
      @pathname = File.join(*[parent&.pathname, "/", @name].compact).to_s
      @children = {}
      @options = {}
      apply_options!(options)
      @first_ancestor = @parent&.first_ancestor || self
      @parent&.add_child(self)
    end

    # Inspect the SchemaNode object without representing the parent or children to avoid
    # large prints.
    #
    # @return [String] The inspection string.
    def inspect
      "#{self.class}(pathname: #{pathname.inspect}, children: #{children.size})"
    end

    # An identifier used during the printing of the tree structure.
    #
    # @return [String] The demodularized class name.
    def schema_node_type
      self.class.name.demodulize.underscore
    end

    # Adherance to the acts_like? interface
    def acts_like_fixtury_schema_node?
      true
    end

    # Adds child to the node's children hash as long as another is not already defined.
    #
    # @param child [Fixtury::SchemaNode] The child node to add.
    # @raise [Fixtury::Errors::AlreadyDefinedError] if the child is already defined and not the provided child.
    # @return [Fixtury::Errors::AlreadyDefinedError] the child that was suscessfully added
    def add_child(child)
      if children.key?(child.name) && children[child.name] != child
        raise Errors::AlreadyDefinedError, child.pathname
      end

      children[child.name] = child
    end

    # Is the current node the first ancestor?
    #
    # @return [TrueClass, FalseClass] `true` if the node is the first ancestor, `false` otherwise.
    def first_ancestor?
      parent.nil?
    end

    # Determines the isolation key in a top-down manner. It first accepts an isolation key
    # set by the parent, then it checks for an isolation key set by the node itself. If no
    # isolation key is found, it defaults to the node's name unless default is set to falsy.
    #
    # @param default [TrueClass, FalseClass, String] if no isolation key is present, what should the default value be?
    #   @option default [true] The default value is the node's name.
    #   @option default [String] The default value is a custom string.
    #   @option default [false, nil, ""] No isolation key should be represented
    # @return [String, NilClass] The isolation key.
    def isolation_key(default: true)
      from_parent = parent&.isolation_key(default: nil)
      return from_parent if from_parent

      value = options[:isolate] || default
      value = (value == true ? pathname : value&.to_s).presence
      value = (value == "/" ? nil : value) # special case to accommodate root nodes
      value.presence
    end

    # Performs get() but raises if the result is nil.
    # @raise [Fixtury::Errors::SchemaNodeNotDefinedError] if the search does not return a node.
    # (see #get)
    def get!(search)
      thing = get(search)
      raise Errors::SchemaNodeNotDefinedError.new(pathname, search) unless thing

      thing
    end

    # Retrieves a node in the tree relative to self. Absolute and relative searches are
    # accepted. The potential absolute paths are determined by a Fixtury::PathResolver instance
    # relative to this node's pathname.
    #
    # @param search [String] The search to be used for finding the node.
    # @return [Fixtury::SchemaNode, NilClass] The node if found, `nil` otherwise.
    # @raise [ArgumentError] if the search is blank.
    # @alias []
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

    # Generates a string representing the structure of the schema tree.
    # The string will be in the form of "type:name[isolation_key](options)". The children
    # will be on the next line and indented by two spaces.
    #
    # @param prefix [String] The prefix to be used for any lines produced.
    # @return [String] The structure string.
    def structure(prefix = "")
      out = []

      opts = options.except(:isolate)
      opts.compact!

      my_structure = +"#{prefix}#{schema_node_type}:#{name}"
      iso = isolation_key(default: nil)
      my_structure << "[#{iso}]" if iso
      my_structure << "(#{opts.to_a.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")})" if opts.present?
      out << my_structure

      children.each_value do |child|
        out << child.structure("#{prefix}  ")
      end
      out.join("\n")
    end

    # Applies options to the node and raises if a collision occurs.
    # This is useful for reopening a node and ensuring options are not altered.
    #
    # @param opts [Hash] The options to apply to the node.
    # @raise [Fixtury::Errors::OptionCollisionError] if the option is already set and the new value is different.
    # @return [void]
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
