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

ActiveRecord::Schema[8.0].define(version: 2025_05_24_065537) do
  create_table "employee_teams", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "team_id", null: false
    t.datetime "joined_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_employee_teams_on_employee_id"
    t.index ["team_id"], name: "index_employee_teams_on_team_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name"
    t.string "role", default: "Employee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.string "status"
    t.string "category"
    t.text "detail"
    t.datetime "due"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["employee_id"], name: "index_tasks_on_employee_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "employee_teams", "employees"
  add_foreign_key "employee_teams", "teams"
  add_foreign_key "tasks", "employees"
end
