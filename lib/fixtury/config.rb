require "singleton"

module Fixtury
  class Config
    include ::Singleton

    LOADERS = {
      default: ->(ref){ ref[:class_name].constantize.unscoped.find(ref[:pk]) }
    }

    DUMPERS = {
      default: ->(value){ { class_name: value.class.name, pk: value.id } }
    }

    attr_accessor :reference_loader
    attr_accessor :reference_dumper

    def initialize
      @reference_loader = DEFAUL
      @reference_dumper = :default
    end

    def reference_loader
      case @reference_loader
      when :default
        -> { }
    end

  end
end
