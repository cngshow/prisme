class CreateTests < ActiveRecord::Migration
  def change
    create_table :tests do |t|
      t.string :foo

      t.timestamps null: false
    end
  end
end
