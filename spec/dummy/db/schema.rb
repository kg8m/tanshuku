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

ActiveRecord::Schema[5.1].define(version: 2023_02_20_123456) do
  create_table "tanshuku_urls", force: :cascade do |t|
    t.text "url", null: false
    t.string "hashed_url", limit: 128, null: false
    t.string "key", limit: 20, null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["hashed_url"], name: "index_tanshuku_urls_on_hashed_url", unique: true
    t.index ["key"], name: "index_tanshuku_urls_on_key", unique: true
  end

end
