class TerminologySourceContent < ActiveRecord::Base
  do_not_validate_attachment_file_type :upload

  class DBValidator < ActiveModel::Validator
    def validate(record)
      unless (record.upload_file_name.end_with? *['.zip','.war','.db'])
        record.errors[:file] << 'needs to be a .war, .zip or .db file!'
      end
   #   file = record.attachment_upload.file.tempfile
    #  $log.debug("the tempfile is #{file}")
      file_there = File.exists?("#{Rails.root}/tmp/terminology_source_upload/#{record.id}/#{record.upload_file_name}")
      $log.debug("is the file #{Rails.root}/tmp/terminology_source_upload/#{record.id}/#{record.upload_file_name} there?: #{file_there}"  )
    end
  end

  has_attached_file :upload, :path => ":rails_root/tmp/terminology_source_upload/:id/:basename.:extension"

  validates_attachment_presence :upload
  #validates_attachment_file_name :upload, matches: [/war\Z/, /zip\Z/, /db\Z/] #, message: "invalid file type."
  validates_with DBValidator
end
