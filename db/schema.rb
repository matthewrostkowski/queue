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

ActiveRecord::Schema[8.0].define(version: 2025_10_29_070327) do
  create_table "queue_items", force: :cascade do |t|
    t.integer "song_id", null: false
    t.integer "queue_session_id", null: false
    t.integer "user_id", null: false
    t.decimal "base_price", precision: 8, scale: 2, null: false
    t.integer "vote_count", default: 0, null: false
    t.integer "base_priority", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["queue_session_id"], name: "index_queue_items_on_queue_session_id"
    t.index ["song_id"], name: "index_queue_items_on_song_id"
    t.index ["user_id"], name: "index_queue_items_on_user_id"
  end

  create_table "queue_sessions", force: :cascade do |t|
    t.integer "venue_id", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["venue_id"], name: "index_queue_sessions_on_venue_id"
  end

  create_table "songs", force: :cascade do |t|
    t.string "title", null: false
    t.string "artist", null: false
    t.string "spotify_id"
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "display_name", null: false
    t.string "auth_provider", null: false
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "password_digest"
  end

  create_table "venues", force: :cascade do |t|
    t.string "name", null: false
    t.string "location", null: false
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "queue_items", "queue_sessions"
  add_foreign_key "queue_items", "songs"
  add_foreign_key "queue_items", "users"
  add_foreign_key "queue_sessions", "venues"
end
