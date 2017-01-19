class CreateVaGroups < ActiveRecord::Migration
  def change
    create_table :va_groups do |t|
      t.string :name
      t.string :member_sites
      t.string :member_groups

      t.timestamps null: false
    end
  end
end
