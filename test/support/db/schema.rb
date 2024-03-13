# frozen_string_literal: true

::ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :first_name, null: false
    t.string :last_name, null: false
    t.date :dob
    t.date :last_login_date
    t.datetime :created_at, null: false
    t.datetime :updated_at, null: false
  end

end
