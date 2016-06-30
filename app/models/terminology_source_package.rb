class TerminologySourcePackage < ActiveRecord::Base
  has_many :terminology_source_contents, :dependent => :destroy
  # accepts_nested_attributes_for :terminology_source_contents, :allow_destroy => true
  accepts_nested_attributes_for :terminology_source_contents
end
