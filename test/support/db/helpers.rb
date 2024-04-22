# frozen_string_literal: true

module Support
  module Db
    module Helpers

      def uses_db
        require "support/db/models"

        prepend DbSetup
      end

      module DbSetup

        def setup
          ::ActiveRecord::Base.establish_connection({
            adapter: "sqlite3",
            database: ":memory:",
          })

          load File.join(__dir__, "schema.rb")
          super
        end
      end

    end
  end
end
