module Fixtury
  # An object which allows access to a specific subset of fixtures
  # in the context of a definition's dependencies.
  class DependencyStore

    attr_reader :definition, :store

    def initialize(definition:, store:)
      @definition = definition
      @store = store
    end

    def inspect
      "#{self.class}(definition: #{definition.pathname.inspect}, dependencies: #{definition.dependencies.keys.inspect})"
    end

    # Returns the value of the dependency with the given key
    #
    # @param key [String, Symbol] the accessor of the dependency
    # @return [Object] the value of the dependency
    # @raise [Fixtury::Errors::UnknownDependencyError] if the definition does not contain the provided dependency
    def get(key)
      dep = definition.dependencies.fetch(key.to_s) do
        raise Errors::UnknownDependencyError.new(definition, key)
      end
      store.get(dep.definition.pathname)
    end
    alias [] get

    # If an accessor is used and we recognize the accessor as a dependency
    # of our definition, we return the value of the dependency.
    def method_missing(method, *args, &block)
      if definition.dependencies.key?(method.to_s)
        get(method)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      definition.dependencies.key?(method.to_s) || super
    end

  end
end
