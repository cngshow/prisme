class CreateChecksumRequests < ActiveRecord::Migration
  def change
    create_table :checksum_requests do |t|
      t.string :username, null: false
      t.string :subset_group, null: false
      t.string :status, null: false
      t.date :start_time
      t.date :finish_time

      t.timestamps null: false
    end
    add_index(:checksum_requests, [:subset_group, :finish_time])
  end
end
# 20170209192046_create_checksum_requests
# class CreateChecksumRequests < ActiveRecord::Migration
#   def change
#     create_table :checksum_requests do |t|
#       t.string :username, null: false
#       t.string :subset_group, null: false #to domain
#       t.string :status, null: false #move to detail
#       t.date :start_time #move to detail
#       t.date :finish_time #move to detail
#
#       t.timestamps null: false
#     end
#     add_index(:checksum_requests, [:subset_group, :finish_time])
#   end
# end