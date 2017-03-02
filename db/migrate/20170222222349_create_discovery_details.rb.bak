class CreateDiscoveryDetails < ActiveRecord::Migration
  def change
    create_table :discovery_details do |t|
      t.references :va_site, index: true, null: false
      t.references :discovery_request, index: true, null: false
      t.references :discovery_detail, index: true, null: true
      t.string :subset
      t.text :discovery_hl7

      t.timestamps null: false
    end
  end
end
# 20170209192335_create_checksum_details.rb