
ActiveRecord::Schema[8.1].define(version: 2026_09_01_120004) do
  enable_extension "pg_catalog.plpgsql"

  create_table "films", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.integer "runtime"
    t.text "synopsis"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["external_id"], name: "index_films_on_external_id", unique: true
  end

  create_table "screenings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.bigint "film_id", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["external_id"], name: "index_screenings_on_external_id", unique: true
    t.index ["film_id"], name: "index_screenings_on_film_id"
    t.index ["starts_at"], name: "index_screenings_on_starts_at"
    t.index ["venue_id"], name: "index_screenings_on_venue_id"
  end

  create_table "sync_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_details"
    t.text "error_summary"
    t.integer "films_created", default: 0, null: false
    t.integer "films_updated", default: 0, null: false
    t.datetime "finished_at"
    t.integer "generation"
    t.integer "records_created", default: 0, null: false
    t.integer "records_failed", default: 0, null: false
    t.integer "records_fetched", default: 0, null: false
    t.integer "records_updated", default: 0, null: false
    t.integer "screenings_created", default: 0, null: false
    t.integer "screenings_updated", default: 0, null: false
    t.datetime "started_at"
    t.string "status", default: "running", null: false
    t.datetime "updated_at", null: false
    t.integer "venues_created", default: 0, null: false
    t.integer "venues_updated", default: 0, null: false
    t.index ["started_at"], name: "index_sync_runs_on_started_at"
    t.index ["status"], name: "index_sync_runs_on_status"
  end

  create_table "venues", force: :cascade do |t|
    t.string "address"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_venues_on_external_id", unique: true
  end

  add_foreign_key "screenings", "films"
  add_foreign_key "screenings", "venues"
end
