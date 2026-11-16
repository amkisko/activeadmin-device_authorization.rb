# frozen_string_literal: true

ActiveRecord::Schema.define(version: 2026_11_16_120000) do
  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], unique: true
    t.index ["reset_password_token"], unique: true
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "device_authorization_clients", force: :cascade do |t|
    t.string "client_id", null: false
    t.string "name", null: false
    t.boolean "enabled", default: true, null: false
    t.text "allowed_scopes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], unique: true
  end

  create_table "device_authorization_grants", force: :cascade do |t|
    t.bigint "device_authorization_client_id", null: false
    t.bigint "admin_user_id"
    t.string "device_code_digest", null: false
    t.string "user_code", null: false
    t.text "requested_scopes"
    t.text "granted_scopes"
    t.string "status", null: false, default: "pending"
    t.datetime "challenge_expires_at", null: false
    t.integer "absolute_ttl_seconds"
    t.integer "poll_interval_seconds"
    t.datetime "last_poll_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_code"], unique: true
    t.index ["device_authorization_client_id", "device_code_digest"],
      unique: true,
      name: "index_device_auth_grants_on_client_and_device_code"
  end

  create_table "device_authorization_access_tokens", force: :cascade do |t|
    t.bigint "device_authorization_client_id", null: false
    t.bigint "admin_user_id", null: false
    t.bigint "device_authorization_grant_id", null: false
    t.string "token_digest", null: false
    t.text "scopes"
    t.datetime "absolute_expires_at", null: false
    t.datetime "last_used_at"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], unique: true
    t.index ["device_authorization_grant_id"], unique: true
  end
end
