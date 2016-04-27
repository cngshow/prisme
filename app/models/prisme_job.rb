class PrismeJob < ActiveRecord::Base
  validates_uniqueness_of :job_id
  self.primary_key = 'job_id'

  has_many :child_jobs, :class_name => 'PrismeJob', :foreign_key => 'parent_job_id'
  belongs_to :parent_job, :class_name => 'PrismeJob', :foreign_key => 'parent_job_id'

  scope :job_name, -> (job_name) {where(job_name: job_name)}
  scope :leaves, -> () {where(leaf: true)}
  scope :completed, -> (bool) {where("status #{bool ? '>=' : '<'} #{PrismeJobConstants::Status::STATUS_HASH[:FAILED]}")}

  def is_leaf?
    child_jobs.count == 0
  end

  def is_root?
    self.parent_job.nil?
  end

  def descendants
    PrismeJob.where(root_job_id: self.job_id)
  end
end
