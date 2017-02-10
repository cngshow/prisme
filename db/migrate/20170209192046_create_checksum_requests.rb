class CreateChecksumRequests < ActiveRecord::Migration
  def change
    create_table :checksum_requests do |t|
      t.string :username
      t.date :start_time
      t.date :finish_time
      t.string :subset_group

      t.timestamps null: false
    end
  end
end
# 20170209192046_create_checksum_requests
