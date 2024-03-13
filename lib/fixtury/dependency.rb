module Fixtury
  class Dependency

    # Resolve a Dependency from a multitude of input types
    # @param parent [Fixtury::Definition] the parent definition
    # @param thing [Fixtury::Dependency, Hash, Array, String, Symbol] the thing to resolve
    #   @option thing [Fixtury::Dependency] a dependency will be cloned.
    #   @option thing [Hash] a hash with exactly one key will be resolved as { accessor => search }.
    #   @option thing [Array] an array with two elements will be resolved as [ accessor, search ].
    #   @option thing [String, Symbol] a string or symbol will be resolved as both the accessor and the search.
    # @return [Array<Fixtury::Dependency>] the resolved dependency
    def self.from(parent, thing)
      out = case thing
      when self
        Dependency.new(parent: parent, search: thing.search, accessor: thing.accessor)
      when Hash
        thing.each_with_object([]) do |(k, v), arr|
          arr << Dependency.new(parent: parent, search: v, accessor: k)
        end
      when Array
        raise ArgumentError, "Array must have an even number of elements" unless thing.size % 2 == 0

        thing.each_slice(2).map do |pair|
          Dependency.new(parent: parent, search: pair[1], accessor: pair[0])
        end
      when String, Symbol
        Dependency.new(parent: parent, search: thing, accessor: thing)
      else
        raise ArgumentError, "Unknown dependency type: #{thing.inspect}"
      end

      Array(out)
    end

    attr_reader :parent, :search, :accessor

    def initialize(parent:, search:, accessor:)
      @parent = parent
      @search = search.to_s
      @accessor = accessor.to_s.split("/").last
    end

    def definition
      @definition ||= parent&.get!(search)
    end

    def inspect
      "#{self.class}(accessor: #{accessor.inspect}, search: #{search.inspect}, parent: #{parent.name.inspect})"
    end

  end
end
