class CreateDiscoveryTables < ActiveRecord::Migration
  def change
    create_table :discovery_requests do |t|
      t.string :username, null: false
      t.string :domain, null: false
      t.timestamps null: false
    end
    add_index(:discovery_requests, [:username, :domain])

    create_table :discovery_details do |t|
      t.references :va_site, index: true, null: false
      t.references :discovery_request, index: true, null: false
      t.references :discovery_detail, index: true, null: true
      t.string :subset, null: false
      t.string :status, null: false
      t.date :start_time
      t.date :finish_time
      t.string :failure_message
      t.text :hl7_message
      t.timestamps null: false
    end
  end
end
