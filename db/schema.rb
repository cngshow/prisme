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

ActiveRecord::Schema.define(version: 20160329150821) do

  create_table "prisme_jobs", id: false, force: :cascade do |t|
    t.string   "job_id",       limit: 255,        null: false
    t.string   "job_name",     limit: 255,        null: false
    t.integer  "status",       limit: 10,         null: false
    t.string   "queue",        limit: 255,        null: false
    t.datetime "scheduled_at", limit: 23,         null: false
    t.datetime "enqueued_at",  limit: 23
    t.datetime "started_at",   limit: 23
    t.datetime "completed_at", limit: 23
    t.text     "last_error",   limit: 2147483647
    t.text     "result",       limit: 2147483647
    t.string   "user",         limit: 255
    t.datetime "created_at",   limit: 23
    t.datetime "updated_at",   limit: 23
  end

  add_index "prisme_jobs", ["completed_at"], name: "prisme_job_completed_at"
  add_index "prisme_jobs", ["job_id"], name: "prisme_job_job_id", unique: true
  add_index "prisme_jobs", ["job_name"], name: "prisme_job_job_name"
  add_index "prisme_jobs", ["queue"], name: "prisme_job_queue"
  add_index "prisme_jobs", ["scheduled_at"], name: "prisme_job_scheduled_at"
  add_index "prisme_jobs", ["status", "scheduled_at"], name: "prisme_job_status"
  add_index "prisme_jobs", ["user", "scheduled_at"], name: "prisme_job_user"

end
