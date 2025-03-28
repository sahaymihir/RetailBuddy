# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_03_27_212347) do
  create_table "dbtools$execution_history", id: :decimal, force: :cascade do |t|
    t.text "hash"
    t.string "created_by"
    t.timestamptz "created_on", precision: 6
    t.string "updated_by"
    t.timestamptz "updated_on", precision: 6
    t.text "statement"
    t.decimal "times"
  end

  create_table "student", primary_key: "regno", id: { type: :string, limit: 50 }, force: :cascade do |t|
  end

  create_table "users", primary_key: "userid", id: :decimal, default: "0.0", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "email", limit: 150, null: false
    t.string "password", null: false
    t.string "role", limit: 20, null: false
    t.string "password_digest"
    t.index ["email"], name: "sys_c0027878", unique: true
  end

end
