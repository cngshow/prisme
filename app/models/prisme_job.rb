class PrismeJob < ActiveRecord::Base
  validates_uniqueness_of :job_id
  self.primary_key = 'job_id'

  has_many :child_jobs, :class_name => 'PrismeJob', :foreign_key => 'parent_job_id'
  belongs_to :parent_job, :class_name => 'PrismeJob', :foreign_key => 'parent_job_id'

  scope :job_name, -> (job_name, exclude = false) {where("job_name #{exclude ? '!=' : '='} ?", job_name)}
  scope :is_root, -> (bool) {where("parent_job_id is #{bool ? '' : 'not'} null")}
  scope :job_tag, -> (job_tag) {where('job_tag = ?', job_tag)}
  scope :leaves, -> () {where(leaf: true)}
  scope :job_ids_in, -> (ids, include) {where("job_id #{include ? 'IN' : 'NOT IN'} (?)", ids.map do |e| "'#{e}'" end.join(','))}
  scope :orphan, -> (bool) {where("status #{bool ? '=' : '!='} ?", PrismeJobConstants::Status::STATUS_HASH[:ORPHANED])}
  scope :completed, -> (bool) {where("status #{bool ? '>=' : '<'} ?", PrismeJobConstants::Status::STATUS_HASH[:FAILED])}
  scope :completed_by, -> (time) {where('completed_at >= ?', time)}

  def self.load_build_data(row_limit)
    PrismeJob.completed_by($PROPS['PRISME.job_queue_trim'].to_i.days.ago)
        .job_name('TerminologyUploadTracker')
        .where('root_job_id is null')
        .orphan(false)
        .order(completed_at: :desc)
        .limit(row_limit)
  end

  def self.has_running_jobs?(name, job_tag = false)
    (job_tag ? PrismeJob.job_tag(name) : PrismeJob.job_name(name)).completed(false).orphan(false).count > 0
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

  def self.orphan?(ar)
    ar.status.eql? PrismeJobConstants::Status::STATUS_HASH[:ORPHANED]
  end

end
