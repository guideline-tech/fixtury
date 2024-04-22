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

    # Returns the value of the dependency with the given key. If the key is not present in the dependencies
    # and strict_dependencies is enabled, an error will be raised. If strict_dependencies is not enabled
    # the store will receive the search term directly.
    #
    # @param search [String, Symbol] the accessor of the dependency
    # @return [Object] the value of the dependency
    # @raise [Fixtury::Errors::UnknownDependencyError] if the definition does not contain the provided dependency and strict_dependencies is enabled
    def get(search)
      dep = definition.dependencies[search.to_s]

      if dep.nil? && Fixtury.configuration.strict_dependencies
        raise Errors::UnknownDependencyError.new(definition, search)
      end

      if dep
        store.get(dep.definition.pathname)
      else
        store.with_relative_schema(definition.parent) do
          store.get(search)
        end
      end
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
