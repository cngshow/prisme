class ChecksumRequest < ActiveRecord::Base
  has_many :checksum_details, :dependent => :destroy

end
