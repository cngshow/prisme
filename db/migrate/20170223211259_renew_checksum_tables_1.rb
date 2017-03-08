class RenewChecksumTables1 < ActiveRecord::Migration
  def change
    drop_table :checksum_details rescue false
    drop_table :checksum_requests rescue false

    create_table :checksum_requests do |t|
      t.string :username, null: false
      t.string :domain, null: false
      t.timestamps null: false
    end

    add_index(:checksum_requests, [:domain])

    create_table :checksum_details do |t|
      t.references :va_site, index: true, null: false
      t.references :checksum_request, index: true, null: false
      t.references :detail, index: true, null: true
      t.string :subset #todo cris this should be required!! , null: false
      t.string :checksum
      t.string :failure_message
      t.text :hl7_message
      t.string :version
      t.string :status, null: false
      t.date :start_time
      t.date :finish_time
      t.timestamps null: false
    end

  end
end


