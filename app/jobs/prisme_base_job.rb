module PrismeJobConstants
  module Status
    NOT_QUEUED = :not_queued
    QUEUED = :queued
    RUNNING = :running
    COMPLETED = :completed
    FAILED = :failed
  end
end

class PrismeBaseJob < ActiveJob::Base
  queue_as :default

  def lookup
    PrismeJob.where(job_id: self.job_id).first
  end

  before_enqueue do |job|
    $log.debug("Preparing to enqueue job #{job}")
    active_record = PrismeJob.new
    active_record.job_id = job.job_id
    active_record.scheduled_at = Time.at(job.scheduled_at)
    active_record.queue = job.queue_name
    active_record.job_name = job.class.to_s
    active_record.status = PrismeJobConstants::Status::NOT_QUEUED
    active_record.save!
  end


  after_enqueue do |job|
    $log.debug("Enqueued job #{job}")
    active_record = lookup
    active_record.status = PrismeJobConstants::Status::QUEUED
    active_record.enqueued_at = Time.now
    active_record.save!
  end

  before_perform do |job|
    active_record = lookup
    $log.debug("Preparing to perform job #{job}")
    active_record.status = PrismeJobConstants::Status::RUNNING
    active_record.started_at = Time.now
    active_record.save!
  end

  after_perform do |job|
    active_record = lookup
    $log.debug("Performed job #{job}")
    active_record.status = PrismeJobConstants::Status::COMPLETED
    active_record.completed_at = Time.now
    active_record.save!
  end

  rescue_from(StandardError) do |exception|
    puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! " + self.job_id
    active_record = lookup
    $log.debug("Rescue block self is " + self.to_s + " Is @act nil : " + active_record.nil?.to_s)
    active_record.last_error = exception.message
    active_record.status = PrismeJobConstants::Status::FAILED
    active_record.completed_at = Time.now
    active_record.save!
  end

  def perform(*args)
    raise NotImplementedError.new("Please implement this in your base class!")
  end

  def to_s
    "Job: " + self.class.to_s + " , ID: " + self.job_id
  end

end
# load('./app/jobs/prisme_base_job.rb')
# job = TestJob.set(wait_until: 5.seconds.from_now).perform_later