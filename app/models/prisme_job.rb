class PrismeJob < ActiveRecord::Base
  validates_uniqueness_of :job_id
  self.primary_key = 'job_id'

  has_many :child_jobs, :class_name => 'PrismeJob', :foreign_key => 'parent_job_id'
  belongs_to :parent_job, :class_name => 'PrismeJob', :foreign_key => 'parent_job_id'

  scope :job_name, -> (job_name, exclude=false) {where("job_name #{exclude ? '!=' : '='} ?", job_name)}
  scope :leaves, -> () {where(leaf: true)}
  scope :job_ids_in, -> (ids,include) {where("job_id #{include ? 'IN' : 'NOT IN'} (#{ids.map do |e| "'#{e}'" end.join(',')})")}
  scope :orphan, -> (bool) {where("status #{bool ? '=' : '!='} #{PrismeJobConstants::Status::STATUS_HASH[:ORPHANED]} ")}
  scope :completed, -> (bool) {where("status #{bool ? '>=' : '<'} #{PrismeJobConstants::Status::STATUS_HASH[:FAILED]}")}

  def self.has_running_jobs?(job_name)
    PrismeJob.job_name(job_name).completed(false).orphan(false).count > 0
  end

  def is_leaf?
    child_jobs.count == 0
  end

  def is_root?
    self.parent_job.nil?
  end

  def descendants
    PrismeJob.where(root_job_id: self.job_id)
  end

  def self.status_string(ar)
    return nil unless ar.is_a? PrismeJob
    s = ar.status
    case s
      when PrismeJobConstants::Status::STATUS_HASH[:NOT_QUEUED]
        'NOT QUEUED'
      when  PrismeJobConstants::Status::STATUS_HASH[:QUEUED]
        'QUEUED'
      when  PrismeJobConstants::Status::STATUS_HASH[:RUNNING]
        'RUNNING'
      when  PrismeJobConstants::Status::STATUS_HASH[:ORPHANED]
        'ORPHANED'
      when  PrismeJobConstants::Status::STATUS_HASH[:FAILED]
        'FAILED'
      when  PrismeJobConstants::Status::STATUS_HASH[:COMPLETED]
        'COMPLETED'
      else
        raise ArgumentError.new('This method needs to be updated!.')
    end
  end

  #should only be called via an initializer on startup.
  def self.tag_orphans(current_job_id)
    orphans = PrismeJob.completed(false).orphan(false).job_ids_in([current_job_id], false)
    orphans.each do |orphan|
      $log.debug("Orphaning a #{orphan.job_name} with id #{orphan.job_id} and status " + status_string(orphan))
      orphan.status = PrismeJobConstants::Status::STATUS_HASH[:ORPHANED]
      parent = orphan.parent_job
      parent.leaf = false unless parent.nil?
      PrismeJob.transaction do
        parent.save! unless parent.nil?
        orphan.save!
      end
      $log.debug("Done orphaning a #{orphan.job_name} with id #{orphan.job_id} and status " + status_string(orphan))
    end
  end
end
=begin

orphans.each do |o|
  unless o.is_root?
    o.parent_job.leaf = false
    o.parent_job.save!
  end
end
=end
