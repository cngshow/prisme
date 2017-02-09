class ChecksumDetail < ActiveRecord::Base
  belongs_to :checksum_request
  has_one :va_site

end
