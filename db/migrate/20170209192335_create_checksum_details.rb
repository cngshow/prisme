class CreateChecksumDetails < ActiveRecord::Migration
  def change
    create_table :checksum_details do |t|
      t.references :va_site, index: true, null: false
      t.references :checksum_request, index: true, null: false
      t.references :checksum_detail, index: true, null: true
      t.string :subset
      t.string :checksum
      t.text :discovery_data
      t.string :version

      t.timestamps null: false
    end
  end
end
# 20170209192335_create_checksum_details.rb