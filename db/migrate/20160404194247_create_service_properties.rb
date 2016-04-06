class CreateServiceProperties < ActiveRecord::Migration
  def change
    create_table :service_properties do |t|
      t.references :service, index: true
      t.string :key
      t.string :value

      t.timestamps null: false
    end
    add_foreign_key :service_properties, :services
  end
end
