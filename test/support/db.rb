# frozen_string_literal: true

require "singleton"

module Support
  class Db

    include Singleton

    class << self

      delegate :read, :write, :clear, :del, to: :instance

    end

    def initialize
      clear
    end

    def read(ref)
      @store[ref.to_s]
    end

    def read!(ref)
      @store.fetch(ref.to_s)
    end

    def write(ref, value)
      @store[ref.to_s] = value
    end

    def clear
      @store = {}
    end

    def del(key)
      @store.delete(key.to_s)
    end

  end
end
