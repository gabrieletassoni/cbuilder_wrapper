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

ActiveRecord::Schema[7.2].define(version: 2025_12_31_161819) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "actions", force: :cascade do |t|
    t.string "name"
    t.bigint "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_actions_on_name", unique: true
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

  create_table "affiliation_leaders", force: :cascade do |t|
    t.bigint "affiliation_id", null: false
    t.bigint "fighter_id", null: false
    t.boolean "required", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliation_id", "fighter_id"], name: "index_affiliation_leaders_on_affiliation_id_and_fighter_id", unique: true
    t.index ["affiliation_id"], name: "index_affiliation_leaders_on_affiliation_id"
    t.index ["fighter_id"], name: "index_affiliation_leaders_on_fighter_id"
  end

  create_table "affiliations", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "army_id", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["army_id", "name"], name: "index_affiliations_on_army_id_and_name"
    t.index ["army_id"], name: "index_affiliations_on_army_id"
  end

  create_table "armies", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.bigint "path_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_armies_on_name", unique: true
    t.index ["path_id"], name: "index_armies_on_path_id"
  end

  create_table "army_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "army_id", null: false
    t.bigint "game_format_id", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "published", default: false
    t.integer "total_points_cache", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["army_id"], name: "index_army_lists_on_army_id"
    t.index ["game_format_id"], name: "index_army_lists_on_game_format_id"
    t.index ["user_id", "published"], name: "index_army_lists_on_user_id_and_published"
    t.index ["user_id"], name: "index_army_lists_on_user_id"
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "cost", default: 0
    t.bigint "army_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["army_id"], name: "index_artifacts_on_army_id"
    t.index ["name"], name: "index_artifacts_on_name", unique: true
  end

  create_table "deities", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_deities_on_name", unique: true
  end

  create_table "equipment", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "cost", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_equipment_on_name", unique: true
  end

  create_table "equipment_profiles", id: false, force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "equipment_id", null: false
    t.index ["profile_id", "equipment_id"], name: "index_equipment_profiles_on_profile_id_and_equipment_id", unique: true
  end

  create_table "fighters", force: :cascade do |t|
    t.string "name", null: false
    t.string "title"
    t.bigint "army_id", null: false
    t.bigint "affiliation_id"
    t.bigint "rank_id", null: false
    t.bigint "size_id", null: false
    t.integer "base_cost", default: 0
    t.float "movement_ground"
    t.float "movement_fly"
    t.integer "initiative"
    t.integer "attack"
    t.integer "strength"
    t.integer "defence"
    t.integer "resilience"
    t.integer "aim"
    t.integer "courage"
    t.integer "fear"
    t.integer "discipline"
    t.integer "power"
    t.integer "faith_create"
    t.integer "faith_alter"
    t.integer "faith_destroy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "base_dice_pool", default: 2, null: false
    t.integer "one_card_every", default: 200
    t.integer "fighters_on_every_card", default: 1, null: false
    t.index ["affiliation_id"], name: "index_fighters_on_affiliation_id"
    t.index ["army_id"], name: "index_fighters_on_army_id"
    t.index ["name"], name: "index_fighters_on_name"
    t.index ["rank_id"], name: "index_fighters_on_rank_id"
    t.index ["size_id"], name: "index_fighters_on_size_id"
  end

  create_table "fighters_keywords", id: false, force: :cascade do |t|
    t.bigint "fighter_id", null: false
    t.bigint "keyword_id", null: false
    t.index ["fighter_id", "keyword_id"], name: "index_fighters_keywords_on_fighter_id_and_keyword_id", unique: true
  end

  create_table "game_formats", force: :cascade do |t|
    t.string "name", null: false
    t.integer "min_points", default: 0
    t.integer "max_points", null: false
    t.integer "min_models", default: 0
    t.integer "min_character_percentage", default: 0
    t.integer "max_character_percentage", default: 50
    t.integer "max_war_machine_percentage", default: 30
    t.integer "max_monster_percentage", default: 30
    t.integer "max_flying_percentage", default: 65
    t.integer "max_scouts_percentage", default: 75
    t.integer "max_scouts_number", default: 9
    t.integer "max_duplicate_profiles", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_game_formats_on_name", unique: true
  end

  create_table "granted_deities", force: :cascade do |t|
    t.string "worshiper_type", null: false
    t.bigint "worshiper_id", null: false
    t.bigint "deity_id", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deity_id"], name: "index_granted_deities_on_deity_id"
    t.index ["worshiper_type", "worshiper_id"], name: "index_granted_deities_on_worshiper"
  end

  create_table "granted_equipments", force: :cascade do |t|
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.bigint "equipment_id", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipment_id"], name: "index_granted_equipments_on_equipment_id"
    t.index ["owner_type", "owner_id"], name: "index_granted_equipments_on_owner"
  end

  create_table "granted_magic_paths", force: :cascade do |t|
    t.string "mage_type", null: false
    t.bigint "mage_id", null: false
    t.bigint "magic_path_id", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mage_type", "mage_id"], name: "index_granted_magic_paths_on_mage"
    t.index ["magic_path_id"], name: "index_granted_magic_paths_on_magic_path_id"
  end

  create_table "granted_skills", force: :cascade do |t|
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.bigint "skill_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.string "condition"
    t.index ["skill_id"], name: "index_granted_skills_on_skill_id"
    t.index ["target_type", "target_id"], name: "index_granted_skills_on_target"
    t.index ["value"], name: "index_granted_skills_on_value"
  end

  create_table "granted_solos", force: :cascade do |t|
    t.string "affiliate_type", null: false
    t.bigint "affiliate_id", null: false
    t.bigint "solo_id", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliate_type", "affiliate_id"], name: "index_granted_solos_on_affiliate"
    t.index ["solo_id"], name: "index_granted_solos_on_solo_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_keywords_on_name", unique: true
  end

  create_table "ldap_servers", force: :cascade do |t|
    t.string "host", null: false
    t.integer "port", default: 389
    t.string "base_dn", null: false
    t.string "admin_user"
    t.string "admin_password"
    t.integer "priority", default: 1
    t.boolean "use_ssl", default: false
    t.string "auth_field", default: "userPrincipalName"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "surname"
    t.string "phone"
    t.string "code"
    t.index ["admin_password"], name: "index_ldap_servers_on_admin_password"
    t.index ["admin_user"], name: "index_ldap_servers_on_admin_user"
    t.index ["auth_field"], name: "index_ldap_servers_on_auth_field"
    t.index ["base_dn"], name: "index_ldap_servers_on_base_dn"
    t.index ["code"], name: "index_ldap_servers_on_code"
    t.index ["host"], name: "index_ldap_servers_on_host"
    t.index ["name"], name: "index_ldap_servers_on_name"
    t.index ["phone"], name: "index_ldap_servers_on_phone"
    t.index ["surname"], name: "index_ldap_servers_on_surname"
  end

  create_table "list_entries", force: :cascade do |t|
    t.bigint "army_list_id", null: false
    t.bigint "profile_id", null: false
    t.integer "quantity", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["army_list_id", "profile_id"], name: "index_list_entries_on_army_list_id_and_profile_id", unique: true
    t.index ["army_list_id"], name: "index_list_entries_on_army_list_id"
    t.index ["profile_id"], name: "index_list_entries_on_profile_id"
  end

  create_table "list_nexuses", force: :cascade do |t|
    t.bigint "army_list_id", null: false
    t.bigint "nexus_id", null: false
    t.integer "quantity", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["army_list_id", "nexus_id"], name: "index_list_nexuses_on_army_list_id_and_nexus_id", unique: true
    t.index ["army_list_id"], name: "index_list_nexuses_on_army_list_id"
    t.index ["nexus_id"], name: "index_list_nexuses_on_nexus_id"
  end

  create_table "magic_paths", force: :cascade do |t|
    t.string "name"
    t.string "element"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_magic_paths_on_name", unique: true
  end

  create_table "miracles", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "deity_id"
    t.bigint "army_id"
    t.string "aspect_creation"
    t.string "aspect_alteration"
    t.string "aspect_destruction"
    t.string "fervor"
    t.string "difficulty"
    t.string "range"
    t.string "duration"
    t.text "effect"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["army_id"], name: "index_miracles_on_army_id"
    t.index ["deity_id"], name: "index_miracles_on_deity_id"
    t.index ["name"], name: "index_miracles_on_name", unique: true
  end

  create_table "nexuses", force: :cascade do |t|
    t.string "name", null: false
    t.integer "resistance"
    t.integer "structure"
    t.integer "cost"
    t.text "effect"
    t.bigint "army_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["army_id"], name: "index_nexuses_on_army_id"
    t.index ["name"], name: "index_nexuses_on_name", unique: true
  end

  create_table "paths", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_paths_on_name", unique: true
  end

  create_table "permission_roles", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "permission_id", null: false
    t.bigint "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_permission_roles_on_permission_id"
    t.index ["role_id"], name: "index_permission_roles_on_role_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.bigint "predicate_id", null: false
    t.bigint "action_id", null: false
    t.bigint "target_id", null: false
    t.bigint "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_id"], name: "index_permissions_on_action_id"
    t.index ["predicate_id"], name: "index_permissions_on_predicate_id"
    t.index ["target_id"], name: "index_permissions_on_target_id"
  end

  create_table "predicates", force: :cascade do |t|
    t.string "name"
    t.bigint "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_predicates_on_name", unique: true
  end

  create_table "profile_modifiers", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "stat_modifier_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id", "stat_modifier_id"], name: "idx_uniq_prof_mod", unique: true
    t.index ["profile_id"], name: "index_profile_modifiers_on_profile_id"
    t.index ["stat_modifier_id"], name: "index_profile_modifiers_on_stat_modifier_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "fighter_id", null: false
    t.bigint "affiliation_id"
    t.string "custom_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliation_id"], name: "index_profiles_on_affiliation_id"
    t.index ["fighter_id"], name: "index_profiles_on_fighter_id"
  end

  create_table "rank_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_rank_categories_on_code", unique: true
  end

  create_table "ranks", force: :cascade do |t|
    t.string "name", null: false
    t.integer "value", default: 1
    t.bigint "rank_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ranks_on_name", unique: true
    t.index ["rank_category_id"], name: "index_ranks_on_rank_category_id"
  end

  create_table "requirements", force: :cascade do |t|
    t.string "restrictable_type", null: false
    t.bigint "restrictable_id", null: false
    t.string "required_entity_type"
    t.bigint "required_entity_id"
    t.string "check_type", null: false
    t.integer "min_value"
    t.integer "max_value"
    t.string "stat_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["required_entity_type", "required_entity_id"], name: "index_requirements_on_required_entity"
    t.index ["restrictable_type", "restrictable_id"], name: "index_requirements_on_restrictable"
  end

  create_table "role_users", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_role_users_on_role_id"
    t.index ["user_id"], name: "index_role_users_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.bigint "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "saved_filters", force: :cascade do |t|
    t.string "abstract_model_name"
    t.string "name"
    t.text "query_string"
    t.bigint "admin_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_saved_filters_on_admin_user_id"
  end

  create_table "sizes", force: :cascade do |t|
    t.string "name", null: false
    t.integer "base_wounds", default: 1
    t.integer "base_force", default: 1
    t.string "base_dimensions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sizes_on_name", unique: true
  end

  create_table "skill_categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["description"], name: "index_skill_categories_on_description"
    t.index ["name"], name: "index_skill_categories_on_name", unique: true
  end

  create_table "skill_categories_skills", id: false, force: :cascade do |t|
    t.bigint "skill_id", null: false
    t.bigint "skill_category_id", null: false
    t.index ["skill_id", "skill_category_id"], name: "idx_on_skill_id_skill_category_id_bc9c4b92c3", unique: true
  end

  create_table "skill_targets", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_skill_targets_on_name", unique: true
  end

  create_table "skills", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.bigint "skill_target_id"
    t.index ["name"], name: "index_skills_on_name", unique: true
    t.index ["skill_target_id"], name: "index_skills_on_skill_target_id"
    t.index ["value"], name: "index_skills_on_value"
  end

  create_table "solos", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "cost", default: 0
    t.bigint "affiliation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["affiliation_id"], name: "index_solos_on_affiliation_id"
    t.index ["name"], name: "index_solos_on_name", unique: true
  end

  create_table "spells", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "magic_path_id"
    t.bigint "army_id"
    t.string "difficulty"
    t.string "cost_string"
    t.string "range"
    t.string "duration"
    t.text "effect"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["army_id"], name: "index_spells_on_army_id"
    t.index ["magic_path_id"], name: "index_spells_on_magic_path_id"
    t.index ["name"], name: "index_spells_on_name", unique: true
  end

  create_table "stat_modifiers", force: :cascade do |t|
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.float "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stat"
    t.string "condition"
    t.index ["source_type", "source_id"], name: "index_stat_modifiers_on_source"
    t.index ["stat"], name: "index_stat_modifiers_on_stat"
  end

  create_table "targets", force: :cascade do |t|
    t.string "name"
    t.bigint "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_targets_on_name", unique: true
  end

  create_table "thecore_settings", force: :cascade do |t|
    t.boolean "enabled", default: true
    t.string "kind", default: "string", null: false
    t.string "ns", default: "main"
    t.string "key", null: false
    t.text "raw"
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_thecore_settings_on_key"
    t.index ["ns", "key"], name: "index_thecore_settings_on_ns_and_key", unique: true
  end

  create_table "used_tokens", force: :cascade do |t|
    t.string "token"
    t.bigint "user_id", null: false
    t.boolean "is_valid", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_used_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_used_tokens_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.jsonb "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_user_preferences_on_name"
    t.index ["user_id"], name: "index_user_preferences_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.boolean "admin", default: false, null: false
    t.bigint "lock_version"
    t.boolean "locked", default: false, null: false
    t.string "locale", default: "en"
    t.string "auth_source", default: "local", null: false
    t.index ["auth_source"], name: "index_users_on_auth_source"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["locale"], name: "index_users_on_locale"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "affiliation_leaders", "affiliations"
  add_foreign_key "affiliation_leaders", "fighters"
  add_foreign_key "affiliations", "armies"
  add_foreign_key "armies", "paths"
  add_foreign_key "army_lists", "armies"
  add_foreign_key "army_lists", "game_formats"
  add_foreign_key "army_lists", "users"
  add_foreign_key "artifacts", "armies"
  add_foreign_key "fighters", "affiliations"
  add_foreign_key "fighters", "armies"
  add_foreign_key "fighters", "ranks"
  add_foreign_key "fighters", "sizes"
  add_foreign_key "granted_deities", "deities"
  add_foreign_key "granted_equipments", "equipment"
  add_foreign_key "granted_magic_paths", "magic_paths"
  add_foreign_key "granted_solos", "solos"
  add_foreign_key "list_entries", "army_lists"
  add_foreign_key "list_entries", "profiles"
  add_foreign_key "list_nexuses", "army_lists"
  add_foreign_key "list_nexuses", "nexuses"
  add_foreign_key "miracles", "armies"
  add_foreign_key "miracles", "deities"
  add_foreign_key "nexuses", "armies"
  add_foreign_key "permission_roles", "permissions"
  add_foreign_key "permission_roles", "roles"
  add_foreign_key "permissions", "actions"
  add_foreign_key "permissions", "predicates"
  add_foreign_key "permissions", "targets"
  add_foreign_key "profile_modifiers", "profiles"
  add_foreign_key "profile_modifiers", "stat_modifiers"
  add_foreign_key "profiles", "affiliations"
  add_foreign_key "profiles", "fighters"
  add_foreign_key "ranks", "rank_categories"
  add_foreign_key "role_users", "roles"
  add_foreign_key "role_users", "users"
  add_foreign_key "saved_filters", "users", column: "admin_user_id"
  add_foreign_key "skills", "skill_targets"
  add_foreign_key "solos", "affiliations"
  add_foreign_key "spells", "armies"
  add_foreign_key "spells", "magic_paths"
  add_foreign_key "used_tokens", "users"
  add_foreign_key "user_preferences", "users"
end
