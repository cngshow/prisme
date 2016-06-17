class AddAttachmentDbFileToTerminologySourceContents < ActiveRecord::Migration
  def self.up
    change_table :terminology_source_contents do |t|
      t.attachment :upload
    end
  end

  def self.down
    remove_attachment :terminology_source_contents, :upload
  end
end
