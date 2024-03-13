# frozen_string_literal: true

require "active_record"
require "globalid"

module Support
  module Db

    class Base < ::ActiveRecord::Base

      include GlobalID::Identification

      self.abstract_class = true

    end

    class User < Base

      self.table_name = :users

    end

  end
end

GlobalID.app = "fixtury-test"
