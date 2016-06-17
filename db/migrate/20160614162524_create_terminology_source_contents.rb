class CreateTerminologySourceContents < ActiveRecord::Migration
  def change
    create_table :terminology_source_contents do |t|
      t.string :user

      t.timestamps null: false
    end
  end
end
