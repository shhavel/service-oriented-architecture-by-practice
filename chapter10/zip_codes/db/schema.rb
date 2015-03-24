# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150216161424) do

  create_table "zip_codes", force: :cascade do |t|
    t.string   "zip",             null: false
    t.string   "street_name"
    t.string   "building_number"
    t.string   "city"
    t.string   "state"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "zip_codes", ["building_number"], name: "index_zip_codes_on_building_number", using: :btree
  add_index "zip_codes", ["city"], name: "index_zip_codes_on_city", using: :btree
  add_index "zip_codes", ["state"], name: "index_zip_codes_on_state", using: :btree
  add_index "zip_codes", ["street_name"], name: "index_zip_codes_on_street_name", using: :btree
  add_index "zip_codes", ["zip"], name: "index_zip_codes_on_zip", using: :btree

end
