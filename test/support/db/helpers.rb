# frozen_string_literal: true

module Support
  module Db
    module Helpers

      extend ActiveSupport::Concern

      class_methods do
        def uses_db
          require "support/db/models"

          alias_method :setup_without_db, :setup
          alias_method :setup, :setup_with_db
        end
      end

      def setup_with_db
        ::ActiveRecord::Base.establish_connection({
          adapter: "sqlite3",
          database: ":memory:",
        })

        load File.join(__dir__, "schema.rb")
        setup_without_db
      end

    end
  end
end
