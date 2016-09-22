class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :name
      t.text :description
      t.string :service_type

      t.timestamps null: false
    end
    add_index :services, [:name], name: 'service_name'
  end
end
