class PrismeJob < ActiveRecord::Base
  validates_uniqueness_of :job_id
  self.primary_key = 'job_id'
end
