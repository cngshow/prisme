class CreateChecksumRequests < ActiveRecord::Migration
  def self.up
    create_table :checksum_requests do |t|
      t.string :username
      t.date :start_time
      t.date :finish_time
      t.string :subset_group

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :checksum_requests
  end

end
# 20170209192046_create_checksum_requests