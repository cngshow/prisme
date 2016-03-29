class CreatePrismeJobs < ActiveRecord::Migration
  def self.up
    create_table :prisme_jobs,{force: true} do |table|
      table.string :job_id, :null => false            # the assigned global_id guid
      table.string :job_name, :null => false          # the name of the job
      table.string :status, :null => false            # not_queued, queued, running, completed, failed
      table.string :queue, :null => false             # The name of the queue this job is in
      table.datetime :scheduled_at, :null => false    # When the job is scheduled to run.
      table.datetime :enqueued_at                     # When the job was put on the queue
      table.datetime :started_at                      # When the job was started
      table.datetime :completed_at                    # When the job was completed
      table.text :last_error                          # reason for last failure (See Note below)
      table.string :user                              # the user requesting the job
      table.timestamps null: true
    end

    add_index :prisme_jobs, [:status, :scheduled_at], name: "prisme_job_status"
    add_index :prisme_jobs, [:user, :scheduled_at], name: "prisme_job_user"
    add_index :prisme_jobs, [:queue], name: "prisme_job_queue"
    add_index :prisme_jobs, [:job_name], name: "prisme_job_job_name"
    add_index :prisme_jobs, [:completed_at], name: "prisme_job_completed_at"
    add_index :prisme_jobs, [:scheduled_at], name: "prisme_job_scheduled_at"
    add_index :prisme_jobs, [:job_id], name: "prisme_job_job_id", :unique => true
  end

  def self.down
    drop_table :prisme_jobs
  end
end
