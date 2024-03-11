# frozen_string_literal: true

module Fixtury
  class Railtie < ::Rails::Railtie

    rake_tasks do
      load "fixtury/tasks.rake"
    end

    initializer "fixtury.activerecord_hooks" do
      require "fixtury/mutation_observer"
    end

  end
end
