class TerminologySourceContent < ActiveRecord::Base
  belongs_to :terminology_source_package
  do_not_validate_attachment_file_type :upload

  ROOT_PATH = '/tmp/terminology_source_upload/'

  has_attached_file :upload, :path => ":rails_root#{ROOT_PATH}:id/:basename.:extension"

  validates_attachment_presence :upload
end
