# frozen_string_literal: true

module Fixtury
  # Takes a namespace as context and a search string and resolves the possible
  # absolute paths that a user could be referring to.
  class PathResolver

    attr_reader :namespace, :search

    def initialize(namespace:, search:)
      @namespace = namespace.to_s
      @search = search.to_s
    end

    def possible_absolute_paths
      @possible_absolute_paths ||= begin
        out = []
        # If the search starts with a slash it's an absolute
        # path and it should be the only possible path.
        if search.start_with?("/")
          out << search

        # Otherwise we need to consider the namespace.
        else
          # Try the namespace as a prefix for the search.
          # This should take priority because it is the most specific.
          out << ::File.join(namespace, search)

          # In addition, someone may be referencing a path relative
          # to root but not including the leading slash. We should
          # consider this case as well.
          out << ::File.join("/", search) unless search.include?(".")
        end

        # Get rid of any `.` and `..` in the paths.
        out.map! { |path| File.expand_path(path, "/").to_s }
        # Get rid of any duplicates.
        out.uniq!
        # voila
        out
      end
    end

  end
end
