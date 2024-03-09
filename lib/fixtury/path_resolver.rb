# frozen_string_literal: true

module Fixtury
  class PathResolver

    attr_reader :namespace, :search

    def initialize(namespace:, search:)
      @namespace = namespace.to_s
      @search = search.to_s
    end

    def possible_absolute_paths
      @possible_absolute_paths ||= begin
        out = []
        if search.start_with?("/")
          out << search
        else
          out << File.expand_path(::File.join(namespace, search), "/")
          out << "/#{search}" unless search.include?(".")
        end
        out.uniq!
        out
      end
    end

  end
end
