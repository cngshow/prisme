class VaSite < ActiveRecord::Base
  validates_uniqueness_of :va_site_id
  self.primary_key = 'va_site_id'

end
