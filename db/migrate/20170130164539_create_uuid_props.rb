class CreateUuidProps < ActiveRecord::Migration

  def self.up
    create_table :uuid_props, {force: true, id: false} do |t|
      t.string :uuid
      t.text :json_data

      t.timestamps null: false
    end
  end

  def self.down
    drop_table :uuid_props
  end
end
