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

ActiveRecord::Schema[7.0].define(version: 2023_10_23_195647) do
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

  create_table "accounts", force: :cascade do |t|
    t.text "public_key", default: ""
    t.string "identifier", default: ""
    t.string "preferred_username", default: ""
    t.string "name", default: ""
    t.string "following", default: ""
    t.string "followers", default: ""
    t.string "inbox", default: ""
    t.string "outbox", default: ""
    t.string "url", default: ""
    t.string "icon", default: ""
    t.text "summary", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "also_known_as", array: true
    t.bigint "moved_to_account_id"
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
    t.bigint "client_app_id"
    t.index ["token"], name: "index_authorization_codes_on_token", unique: true
    t.index ["user_id"], name: "index_authorization_codes_on_user_id"
  end

  create_table "client_apps", force: :cascade do |t|
    t.string "url"
    t.string "name"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "target_account_id", null: false
    t.string "identifier"
    t.string "uri"
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "target_account_id"], name: "index_follows_on_account_id_and_target_account_id", unique: true
    t.index ["identifier"], name: "index_follows_on_identifier"
  end

  create_table "statuses", force: :cascade do |t|
    t.string "language"
    t.string "uri"
    t.integer "visibility", default: 0, null: false
    t.text "text", default: "", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "reblog_of_id"
    t.string "url"
    t.bigint "in_reply_to_id"
    t.string "in_reply_to_uri"
    t.index ["account_id"], name: "index_statuses_on_account_id"
    t.index ["in_reply_to_id"], name: "index_statuses_on_in_reply_to_id"
    t.index ["reblog_of_id"], name: "index_statuses_on_reblog_of_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url", default: ""
    t.string "username", default: "", null: false
    t.string "domain", default: "", null: false
    t.text "public_key", default: "", null: false
    t.text "private_key"
    t.bigint "account_id"
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  add_foreign_key "access_tokens", "authorization_codes"
  add_foreign_key "access_tokens", "users"
  add_foreign_key "authorization_codes", "users"
  add_foreign_key "statuses", "accounts"
end
