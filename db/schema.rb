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

ActiveRecord::Schema[7.0].define(version: 2024_03_28_235218) do
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
    t.string "domain"
    t.string "image", default: ""
    t.index ["preferred_username", "domain"], name: "index_accounts_on_preferred_username_and_domain", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
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

  create_table "likes", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "status_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_likes_on_account_id"
    t.index ["status_id"], name: "index_likes_on_status_id"
  end

  create_table "media_attachments", force: :cascade do |t|
    t.string "remote_url", default: "", null: false
    t.bigint "status_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description", default: ""
    t.string "content_type", default: ""
    t.index ["account_id"], name: "index_media_attachments_on_account_id"
    t.index ["status_id"], name: "index_media_attachments_on_status_id"
  end

  create_table "mentions", force: :cascade do |t|
    t.integer "account_id"
    t.integer "status_id"
    t.boolean "silent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status_id"], name: "index_mentions_on_account_id_and_status_id", unique: true
    t.index ["status_id"], name: "index_mentions_on_status_id"
  end

  create_table "preferences", force: :cascade do |t|
    t.boolean "enable_registrations", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
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
    t.bigint "direct_recipient_id"
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
    t.string "domain", default: "", null: false
    t.text "public_key", default: "", null: false
    t.text "private_key"
    t.bigint "account_id"
    t.string "username"
    t.string "language", default: "en"
    t.boolean "guest", default: true
    t.index ["account_id"], name: "index_users_on_account_id"
  end

  add_foreign_key "access_tokens", "authorization_codes"
  add_foreign_key "access_tokens", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "authorization_codes", "users"
  add_foreign_key "likes", "accounts"
  add_foreign_key "likes", "statuses"
  add_foreign_key "media_attachments", "accounts"
  add_foreign_key "media_attachments", "statuses"
  add_foreign_key "statuses", "accounts"
end
