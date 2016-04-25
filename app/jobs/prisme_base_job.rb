module PrismeJobConstants
  module Status
    STATUS_HASH = {
        NOT_QUEUED: 0,
        QUEUED: 1,
        RUNNING: 2,
        FAILED: 3,
        COMPLETED: 4,
    }
  end

  module User
    SYSTEM = :"Prisme System"
  end
end

class PrismeBaseJob < ActiveJob::Base
  queue_as :default

  def lookup
    active_record = PrismeJob.find_by(job_id: self.job_id)
    if (active_record.nil?)
      active_record = PrismeJob.new
      active_record.user = default_user if self.respond_to? :default_user
      active_record.job_id = self.job_id
      active_record.scheduled_at = Time.at(self.scheduled_at) unless self.scheduled_at.nil?
      active_record.scheduled_at = Time.now if self.scheduled_at.nil?
      active_record.queue = self.queue_name
      active_record.job_name = self.class.to_s
      active_record.status = PrismeJobConstants::Status::STATUS_HASH[:NOT_QUEUED]
    end
    active_record
  end

  def save_result(results)
    active_record = lookup
    active_record.result= results
    active_record.save!
  end

  before_enqueue do |job|
    #this lifecycle is skipped on job.perform_now
    $log.debug("Preparing to enqueue job #{job}")
    lookup.save!
  end


  after_enqueue do |job|
    #this lifecycle is skipped on job.perform_now
    $log.debug("Enqueued job #{job}")
    active_record = lookup
    active_record.status = PrismeJobConstants::Status::STATUS_HASH[:QUEUED]
    active_record.enqueued_at = Time.now
    active_record.save!
  end

  before_perform do |job|
    active_record = lookup
    $log.debug("Preparing to perform job #{job}")
    active_record.status = PrismeJobConstants::Status::STATUS_HASH[:RUNNING]
    active_record.started_at = Time.now
    active_record.save!
  end

  after_perform do |job|
    active_record = lookup
    $log.debug("Performed job #{job}")
    active_record.status = PrismeJobConstants::Status::STATUS_HASH[:COMPLETED]
    active_record.completed_at = Time.now
    parent = parent_id
    active_record.parent_id = parent unless parent.nil? #greg bowman
    active_record.save!
  end

  rescue_from(StandardError) do |exception|
    begin
      active_record = lookup
      active_record.last_error = exception.message
      $log.error("Job failed: " + self.to_s + ". Error message is: " + exception.message)
      $log.error(exception.backtrace.join("\n"))
      active_record.status = PrismeJobConstants::Status::STATUS_HASH[:FAILED]
      active_record.completed_at = Time.now
      active_record.save!
    rescue => e
      $log.error(self.to_s + " failed to rescue from an exception.  The error is " + e.message)
      $log.error(e.backtrace.join("\n"))
    end
  end

  def perform(*args)
    raise NotImplementedError.new("Please implement this in your base class!")
  end

  def to_s
    "Job: " + self.class.to_s + " , ID: " + self.job_id.to_s
  end

  def track_parent(job)
    @@job_map ||= {}
    @@job_map[job.job_id] = job_id
  end

  def parent_id(clean = true)
    @@job_map ||= {}
    parent = nil
    parent = @@job_map[job_id]
    @@job_map.delete(job_id) if clean
    parent
  end

end
# load('./app/jobs/prisme_base_job.rb')
# job = TestJob.set(wait_until: 5.seconds.from_now).perform_later
# job = TestJob.set(wait: 1.days).perform_later
# job = TestJob.set(wait_until: 60.seconds.from_now).perform_later
# job = TestJob.perform_later
#convert status example
# PrismeJobConstants::Status::STATUS_HASH.invert[PrismeJob.all[1].status]