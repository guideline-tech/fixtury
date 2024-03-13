# frozen_string_literal: true

require "fixtury"

module Fixtury
  class Railtie < ::Rails::Railtie

    initializer "fixtury.configure" do
      ::Fixtury.configure do |config|
        config.filepath = Rails.root.join("tmp/fixtury.yml")
        config.add_dependency_path ::Rails.root.join("db/schema.rb")
        config.add_dependency_path ::Rails.root.join("db/seeds.rb")
        config.add_dependency_path ::Rails.root.join("db/seeds/**/*.rb")
        config.add_fixture_path ::Rails.root.join("test/fixtures/**/*.rb")
        config.locator_backend = :global_id
      end
    end

    initializer "fixtury.load_hooks" do
      ActiveSupport.on_load(:active_record) do
        require "fixtury/mutation_observer"
        prepend Fixtury::MutationObserver::ActiveRecordHooks
      end

      ActiveSupport.on_load(:active_support_test_case) do
        require "fixtury/minitest_hooks"
        prepend Fixtury::MinitestHooks

        ::Minitest.after_run do
          ::Fixtury.configuration.dump_file
        end
      end
    end

  end
end
