# frozen_string_literal: true

module Fixtury
  class Path

    def initialize(namespace:, path:)
      @namespace = namespace.to_s
      @path = path.to_s
      @full_path = (
        @path.start_with?("/") ?
        @path :
        File.expand_path(::File.join(@namespace, @path), "/")
      )
      @segments = @full_path.split("/")
    end

    def relative?
      @path.start_with?(".")
    end

    def possible_absolute_paths
      @possible_absolute_paths ||= begin
        out = [@full_path]
        out << @path unless relative?
        out.uniq!
        out
      end
    end

  end
end
