class CreateTerminologySourceContents < ActiveRecord::Migration
  def change
    create_table :terminology_source_contents do |t|
      t.attachment :upload
      t.references :terminology_source_package, index: {name: 'idx_terminology_package'}
      t.timestamps null: false
    end

    add_foreign_key :terminology_source_contents, :terminology_source_packages
  end
end
