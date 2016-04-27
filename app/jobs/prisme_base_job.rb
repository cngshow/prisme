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
    SYSTEM = :'Prisme System'
  end
end

class PrismeBaseJob < ActiveJob::Base
  queue_as :default

  def lookup
    prisme_job = PrismeJob.find_by(job_id: self.job_id)

    unless prisme_job
      prisme_job = PrismeJob.new
      prisme_job.user = default_user if self.respond_to? :default_user
      prisme_job.job_id = self.job_id
      prisme_job.scheduled_at = Time.at(self.scheduled_at) unless self.scheduled_at.nil?
      prisme_job.scheduled_at = Time.now if self.scheduled_at.nil?
      prisme_job.queue = self.queue_name
      prisme_job.job_name = self.class.to_s
      prisme_job.status = PrismeJobConstants::Status::STATUS_HASH[:NOT_QUEUED]

      if arguments && arguments.last.is_a?(Hash)
        hash_args = arguments.last

        if hash_args.has_key?(:parent_job_id)
          parent_job_id = hash_args[:parent_job_id]
          $log.debug('------------- setting the parent_job_id for ' + self.job_id + ' to ' + parent_job_id)
          prisme_job.parent_job_id = parent_job_id
        end

        if hash_args.has_key?(:root_job_id)
          root_job_id = hash_args[:root_job_id].nil? ? hash_args[:parent_job_id] : hash_args[:root_job_id]
          $log.debug('------------- setting the root_job_id for ' + self.job_id + ' to ' + root_job_id)
          prisme_job.root_job_id = root_job_id
        end
      end
    end
    prisme_job
  end

  def save_result(results)
    active_record = lookup
    active_record.result= results
    active_record.save!
  end

  before_enqueue do |job|
    #this lifecycle is skipped on job.perform_now
    $log.debug("Preparing to enqueue job #{job}")
    $log.debug("job arguments = #{job.arguments}")
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
    active_record.save!
  end

  rescue_from(StandardError) do |exception|
    begin
      active_record = lookup
      active_record.last_error = exception.message
      $log.error('Job failed: ' + self.to_s + '. Error message is: ' + exception.message)
      $log.error(exception.backtrace.join("\n"))
      active_record.status = PrismeJobConstants::Status::STATUS_HASH[:FAILED]
      active_record.completed_at = Time.now
      active_record.save!
    rescue => e
      $log.error(self.to_s + ' failed to rescue from an exception.  The error is ' + e.message)
      $log.error(e.backtrace.join("\n"))
    end
  end

  def perform(*args)
    raise NotImplementedError.new('Please implement this in your base class!')
  end

  def to_s
    'Job: ' + self.class.to_s + ' , ID: ' + self.job_id.to_s
  end
end

# load('./app/jobs/prisme_base_job.rb')
# job = TestJob.set(wait_until: 5.seconds.from_now).perform_later
# job = TestJob.set(wait: 1.days).perform_later
# job = TestJob.set(wait_until: 60.seconds.from_now).perform_later
# job = TestJob.perform_later
#convert status example
# PrismeJobConstants::Status::STATUS_HASH.invert[PrismeJob.all[1].status]