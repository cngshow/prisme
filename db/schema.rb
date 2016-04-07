# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160404194247) do

  create_table "prisme_jobs", id: false, force: :cascade do |t|
    t.string   "job_id",       limit: 255, null: false
    t.string   "job_name",     limit: 255, null: false
    t.integer  "status",                   null: false
    t.string   "queue",        limit: 255, null: false
    t.datetime "scheduled_at",             null: false
    t.datetime "enqueued_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text     "last_error"
    t.text     "result"
    t.string   "user",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prisme_jobs", ["completed_at"], name: "prisme_job_completed_at"
  add_index "prisme_jobs", ["job_id"], name: "prisme_job_job_id", unique: true
  add_index "prisme_jobs", ["job_name"], name: "prisme_job_job_name"
  add_index "prisme_jobs", ["queue"], name: "prisme_job_queue"
  add_index "prisme_jobs", ["scheduled_at"], name: "prisme_job_scheduled_at"
  add_index "prisme_jobs", ["status", "scheduled_at"], name: "prisme_job_status"
  add_index "prisme_jobs", ["user", "scheduled_at"], name: "prisme_job_user"

  create_table "service_properties", force: :cascade do |t|
    t.integer  "service_id"
    t.string   "key",        limit: 255
    t.string   "value",      limit: 255
    t.integer  "order_idx"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "service_properties", ["service_id"], name: "index_service_properties_on_service_id"

  create_table "services", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.text     "description"
    t.string   "service_type", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "services", ["name"], name: "service_name"

end
