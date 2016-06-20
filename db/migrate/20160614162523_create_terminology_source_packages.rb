class CreateTerminologySourcePackages < ActiveRecord::Migration
  def change
    create_table :terminology_source_packages do |t|
      t.string :user

      t.timestamps null: false
    end
  end
end
