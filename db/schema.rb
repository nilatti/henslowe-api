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

ActiveRecord::Schema.define(version: 2021_10_26_112444) do

  create_table "active_admin_comments", charset: "utf8mb3", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "active_storage_attachments", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb3", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "acts", charset: "utf8mb3", force: :cascade do |t|
    t.integer "number"
    t.bigint "play_id"
    t.text "summary"
    t.integer "start_page"
    t.integer "end_page"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "heading"
    t.float "original_line_count"
    t.float "new_line_count"
    t.index ["play_id"], name: "index_acts_on_play_id"
  end

  create_table "acts_rehearsals", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "act_id", null: false
    t.bigint "rehearsal_id", null: false
  end

  create_table "admin_users", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "authors", charset: "utf8mb3", force: :cascade do |t|
    t.date "birthdate"
    t.date "deathdate"
    t.string "nationality"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "gender"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "character_groups", charset: "latin1", force: :cascade do |t|
    t.string "name"
    t.string "xml_id"
    t.string "corresp"
    t.bigint "play_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["play_id"], name: "index_character_groups_on_play_id"
  end

  create_table "character_groups_entrance_exits", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "character_group_id", null: false
    t.bigint "entrance_exit_id", null: false
    t.index ["character_group_id", "entrance_exit_id"], name: "index_character_groups_entrance_exits"
  end

  create_table "character_groups_stage_directions", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "character_group_id", null: false
    t.bigint "stage_direction_id", null: false
    t.index ["character_group_id", "stage_direction_id"], name: "index_character_groups_stage_directions"
  end

  create_table "characters", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "age"
    t.string "gender"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "play_id"
    t.string "xml_id"
    t.string "corresp"
    t.bigint "character_group_id"
    t.integer "original_line_count"
    t.integer "new_line_count"
    t.index ["character_group_id"], name: "index_characters_on_character_group_id"
    t.index ["play_id"], name: "index_characters_on_play_id"
  end

  create_table "characters_entrance_exits", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.bigint "entrance_exit_id", null: false
  end

  create_table "characters_stage_directions", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.bigint "stage_direction_id", null: false
    t.index ["character_id", "stage_direction_id"], name: "index_characters_stage_directions"
  end

  create_table "conflict_patterns", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "space_id"
    t.string "start_time"
    t.string "end_time"
    t.string "category"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "days_of_week"
    t.index ["space_id"], name: "index_conflict_patterns_on_space_id"
    t.index ["user_id"], name: "index_conflict_patterns_on_user_id"
  end

  create_table "conflicts", charset: "latin1", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "category"
    t.bigint "space_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "regular", default: false
    t.bigint "conflict_pattern_id"
    t.index ["conflict_pattern_id"], name: "index_conflicts_on_conflict_pattern_id"
    t.index ["space_id"], name: "index_conflicts_on_space_id"
    t.index ["user_id"], name: "index_conflicts_on_user_id"
  end

  create_table "entrance_exits", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "french_scene_id"
    t.integer "page"
    t.integer "line"
    t.integer "order"
    t.bigint "stage_exit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.text "notes"
    t.bigint "user_id"
    t.index ["french_scene_id"], name: "index_entrance_exits_on_french_scene_id"
    t.index ["stage_exit_id"], name: "index_entrance_exits_on_stage_exit_id"
    t.index ["user_id"], name: "index_entrance_exits_on_user_id"
  end

  create_table "french_scenes", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "scene_id"
    t.string "number"
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "end_page"
    t.integer "start_page"
    t.float "original_line_count"
    t.float "new_line_count"
    t.index ["scene_id"], name: "index_french_scenes_on_scene_id"
  end

  create_table "french_scenes_rehearsals", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "french_scene_id", null: false
    t.bigint "rehearsal_id", null: false
  end

  create_table "jobs", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "production_id"
    t.bigint "specialization_id"
    t.bigint "user_id"
    t.date "start_date"
    t.date "end_date"
    t.bigint "theater_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "character_id"
    t.index ["character_id"], name: "index_jobs_on_character_id"
    t.index ["production_id"], name: "index_jobs_on_production_id"
    t.index ["specialization_id"], name: "index_jobs_on_specialization_id"
    t.index ["theater_id"], name: "index_jobs_on_theater_id"
    t.index ["user_id"], name: "index_jobs_on_user_id"
  end

  create_table "jwt_denylist", charset: "utf8mb3", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "labels", charset: "latin1", force: :cascade do |t|
    t.string "xml_id"
    t.string "line_number"
    t.string "content"
    t.bigint "french_scene_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["french_scene_id"], name: "index_labels_on_french_scene_id"
  end

  create_table "lines", charset: "latin1", force: :cascade do |t|
    t.string "ana"
    t.bigint "character_id"
    t.text "corresp"
    t.bigint "french_scene_id", null: false
    t.string "next"
    t.string "number"
    t.string "prev"
    t.string "kind"
    t.string "xml_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "character_group_id"
    t.text "original_content", size: :medium
    t.text "new_content", size: :medium
    t.float "original_line_count"
    t.float "new_line_count"
    t.index ["character_group_id"], name: "index_lines_on_character_group_id"
    t.index ["character_id"], name: "index_lines_on_character_id"
    t.index ["french_scene_id"], name: "index_lines_on_french_scene_id"
  end

  create_table "oauth_access_grants", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "on_stages", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "character_id"
    t.bigint "user_id"
    t.bigint "french_scene_id"
    t.text "description"
    t.text "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "nonspeaking", default: false
    t.bigint "character_group_id"
    t.index ["character_group_id"], name: "index_on_stages_on_character_group_id"
    t.index ["french_scene_id", "character_group_id"], name: "index_on_stages_on_french_scene_id_and_character_group_id", unique: true
    t.index ["french_scene_id", "character_id"], name: "index_on_stages_on_french_scene_id_and_character_id", unique: true
  end

  create_table "plays", charset: "utf8mb3", force: :cascade do |t|
    t.string "title"
    t.bigint "author_id"
    t.date "date"
    t.string "genre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "canonical", default: false
    t.text "text_notes"
    t.bigint "production_id"
    t.integer "original_play_id"
    t.text "synopsis"
    t.float "original_line_count"
    t.float "new_line_count"
    t.boolean "production_copy_complete", default: false
    t.index ["author_id"], name: "index_plays_on_author_id"
    t.index ["production_id"], name: "index_plays_on_production_id"
  end

  create_table "productions", charset: "utf8mb3", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.bigint "theater_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lines_per_minute"
    t.index ["theater_id"], name: "index_productions_on_theater_id"
  end

  create_table "rehearsals", charset: "latin1", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.bigint "space_id"
    t.text "notes"
    t.string "title"
    t.bigint "production_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "text_unit"
    t.index ["production_id"], name: "index_rehearsals_on_production_id"
    t.index ["space_id"], name: "index_rehearsals_on_space_id"
  end

  create_table "rehearsals_scenes", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "scene_id", null: false
    t.bigint "rehearsal_id", null: false
  end

  create_table "rehearsals_users", id: false, charset: "latin1", force: :cascade do |t|
    t.bigint "rehearsal_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "scenes", charset: "utf8mb3", force: :cascade do |t|
    t.integer "number"
    t.text "summary"
    t.bigint "act_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "end_page"
    t.integer "start_page"
    t.string "heading"
    t.float "original_line_count"
    t.float "new_line_count"
    t.index ["act_id"], name: "index_scenes_on_act_id"
  end

  create_table "sound_cues", charset: "latin1", force: :cascade do |t|
    t.string "xml_id"
    t.string "line_number"
    t.string "kind"
    t.bigint "french_scene_id", null: false
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "original_content"
    t.text "new_content"
    t.index ["french_scene_id"], name: "index_sound_cues_on_french_scene_id"
  end

  create_table "space_agreements", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "theater_id"
    t.bigint "space_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["space_id"], name: "index_space_agreements_on_space_id"
    t.index ["theater_id"], name: "index_space_agreements_on_theater_id"
  end

  create_table "spaces", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "phone_number"
    t.string "website"
    t.integer "seating_capacity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "mission_statement"
    t.string "logo"
  end

  create_table "specializations", charset: "utf8mb3", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "production_admin", default: false
    t.boolean "theater_admin", default: false
  end

  create_table "stage_directions", charset: "latin1", force: :cascade do |t|
    t.bigint "french_scene_id", null: false
    t.string "number"
    t.string "kind"
    t.string "xml_id"
    t.text "original_content", size: :medium
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "new_content", size: :medium
    t.index ["french_scene_id"], name: "index_stage_directions_on_french_scene_id"
  end

  create_table "stage_exits", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "production_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["production_id"], name: "index_stage_exits_on_production_id"
  end

  create_table "theaters", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "phone_number"
    t.text "mission_statement"
    t.string "website"
    t.string "calendar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "logo"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "phone_number"
    t.date "birthdate"
    t.string "timezone"
    t.string "gender"
    t.text "bio"
    t.text "description"
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "website"
    t.string "emergency_contact_name"
    t.string "emergency_contact_number"
    t.string "preferred_name"
    t.string "program_name"
    t.boolean "fake", default: false
    t.text "authentication_token"
    t.datetime "authentication_token_created_at"
    t.string "role", default: "regular"
    t.string "provider"
    t.string "uid"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true, length: 255
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "words", charset: "latin1", force: :cascade do |t|
    t.string "kind"
    t.string "content"
    t.string "xml_id"
    t.bigint "line_id"
    t.string "line_number"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "play_id", null: false
    t.index ["line_id"], name: "index_words_on_line_id"
    t.index ["play_id"], name: "index_words_on_play_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "acts", "plays"
  add_foreign_key "character_groups", "plays"
  add_foreign_key "characters", "character_groups"
  add_foreign_key "conflict_patterns", "spaces"
  add_foreign_key "conflict_patterns", "users"
  add_foreign_key "conflicts", "conflict_patterns"
  add_foreign_key "conflicts", "spaces"
  add_foreign_key "conflicts", "users"
  add_foreign_key "entrance_exits", "french_scenes"
  add_foreign_key "entrance_exits", "stage_exits"
  add_foreign_key "french_scenes", "scenes"
  add_foreign_key "jobs", "characters"
  add_foreign_key "jobs", "productions"
  add_foreign_key "jobs", "specializations"
  add_foreign_key "jobs", "theaters"
  add_foreign_key "jobs", "users"
  add_foreign_key "labels", "french_scenes"
  add_foreign_key "lines", "character_groups"
  add_foreign_key "lines", "characters"
  add_foreign_key "lines", "french_scenes"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "on_stages", "character_groups"
  add_foreign_key "plays", "authors"
  add_foreign_key "productions", "theaters"
  add_foreign_key "rehearsals", "productions"
  add_foreign_key "rehearsals", "spaces"
  add_foreign_key "sound_cues", "french_scenes"
  add_foreign_key "space_agreements", "spaces"
  add_foreign_key "space_agreements", "theaters"
  add_foreign_key "stage_directions", "french_scenes"
  add_foreign_key "stage_exits", "productions"
  add_foreign_key "words", "lines"
  add_foreign_key "words", "plays"
end
