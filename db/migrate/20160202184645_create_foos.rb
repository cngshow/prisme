class CreateFoos < ActiveRecord::Migration
  def change
    create_table :foos do |t|
      t.string :faa

      t.timestamps null: false
    end
  end
end
#CREATE TABLE foos (faa varchar(20))