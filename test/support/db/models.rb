# frozen_string_literal: true

require "active_record"

module Support
  module Db

    class User < ::ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord

      self.table_name = :users

    end

  end
end
