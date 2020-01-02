# frozen_string_literal: true

module Fixtury
  class Railtie < ::Rails::Railtie

    rake_tasks do
      load "fixtury/tasks.rake"
    end

  end
end
