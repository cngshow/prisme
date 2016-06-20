class TerminologySourceContent < ActiveRecord::Base
  belongs_to :terminology_source_package
  do_not_validate_attachment_file_type :upload

  has_attached_file :upload, :path => ':rails_root/tmp/terminology_source_upload/:id/:basename.:extension'

  validates_attachment_presence :upload
end
