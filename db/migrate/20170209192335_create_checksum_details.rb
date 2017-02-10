class CreateChecksumDetails < ActiveRecord::Migration
  def change
    create_table :checksum_details do |t|
      t.references :va_site, index: true
      t.references :checksum_request, index: true
      t.string :subset
      t.string :checksum
      t.text :discovery_data
      t.string :version

      t.timestamps null: false
    end
    #add_foreign_key :checksum_details, :checksum_requests
  end
end
# 20170209192335_create_checksum_details.rb