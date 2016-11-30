class CreateLogEvents < ActiveRecord::Migration
  def change
    create_table :log_events do |t|
      t.string :hostname
      t.string :application_name
      t.integer :level
      t.string :tag
      t.text :message
      t.string :acknowledged_by
      t.datetime :acknowledged_on
      t.text :ack_comment

      t.timestamps null: false
    end
    add_index(:log_events, [:hostname])
    add_index(:log_events, [:application_name])
    add_index(:log_events, [:application_name, :tag])
    add_index(:log_events, [:level])
    add_index(:log_events, [:tag])
    add_index(:log_events, [:acknowledged_by])
    add_index(:log_events, [:acknowledged_on])
    add_index(:log_events, [:created_at])
  end
end
