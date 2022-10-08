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

ActiveRecord::Schema[7.0].define(version: 2022_10_07_053214) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.string "token"
    t.bigint "authorization_code_id", null: false
    t.bigint "user_id", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authorization_code_id"], name: "index_access_tokens_on_authorization_code_id"
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_access_tokens_on_user_id"
  end

  create_table "authorization_codes", force: :cascade do |t|
    t.string "token"
    t.string "client_id"
    t.bigint "user_id", null: false
    t.string "redirect_uri"
    t.datetime "expires_at"
    t.string "scope"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pkce_challenge", default: ""
    t.index ["token"], name: "index_authorization_codes_on_token", unique: true
    t.index ["user_id"], name: "index_authorization_codes_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url", default: ""
  end

  add_foreign_key "access_tokens", "authorization_codes"
  add_foreign_key "access_tokens", "users"
  add_foreign_key "authorization_codes", "users"
end
