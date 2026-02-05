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

ActiveRecord::Schema[7.2].define(version: 2026_02_05_030158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "tarot_result_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tarot_result_id"], name: "index_likes_on_tarot_result_id"
    t.index ["user_id", "tarot_result_id"], name: "index_likes_on_user_id_and_tarot_result_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "nickname"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "tarot_cards", force: :cascade do |t|
    t.string "name"
    t.boolean "upright"
    t.text "meaning"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tarot_result_cards", force: :cascade do |t|
    t.bigint "tarot_result_id", null: false
    t.bigint "tarot_card_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "orientation"
    t.index ["tarot_card_id"], name: "index_tarot_result_cards_on_tarot_card_id"
    t.index ["tarot_result_id", "position"], name: "index_tarot_result_cards_on_tarot_result_id_and_position", unique: true
    t.index ["tarot_result_id"], name: "index_tarot_result_cards_on_tarot_result_id"
  end

  create_table "tarot_results", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "fortune_type", default: "today", null: false
    t.string "genre"
    t.string "emotion"
    t.string "question"
    t.text "result_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tarot_card_id"
    t.string "mode", null: false
    t.date "generated_on", null: false
    t.index ["tarot_card_id"], name: "index_tarot_results_on_tarot_card_id"
    t.index ["user_id", "mode", "generated_on"], name: "index_tarot_results_unique_daily_per_mode", unique: true
    t.index ["user_id"], name: "index_tarot_results_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "likes", "tarot_results"
  add_foreign_key "likes", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "tarot_result_cards", "tarot_cards"
  add_foreign_key "tarot_result_cards", "tarot_results"
  add_foreign_key "tarot_results", "tarot_cards"
  add_foreign_key "tarot_results", "users"
end
