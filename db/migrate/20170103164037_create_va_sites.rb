class CreateVaSites < ActiveRecord::Migration
  def self.up
    create_table :va_sites, {force: true, id: false} do |t|
      t.string :va_site_id, :null => false
      t.string :name, :null => false
      t.string :site_type, :null => false
      t.string :message_type, :null => false

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :va_sites
  end
end
