class VaSite < ActiveRecord::Base
  validates_uniqueness_of :va_site_id
  self.primary_key = 'va_site_id'
  include InterestingColumnCompare
end

#load('./app/models/va_site.rb')