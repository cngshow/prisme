class PrismeCleanupJob < PrismeBaseJob
  queue_as :default
  include JenkinsClient
  def default_user
    PrismeJobConstants::User::SYSTEM
  end

  def perform(*args)
    params = [$PROPS['PRISME.job_queue_trim'].to_i.days.ago,
              PrismeJobConstants::Status::STATUS_HASH[:COMPLETED],
              PrismeJobConstants::Status::STATUS_HASH[:FAILED],
    ]
    result = ""
    begin
      # delete all jobs that are x days old
      cnt = PrismeJob.delete_all(['completed_at < ? AND (status = ? OR status= ?)', *params])
      result = "PrismeCleanupJob deleted #{cnt} old records from the prisme_jobs table.\n"
      # schedule this job to run again one day from now
      status = clean_up_old_jobs
      result = status.join("\n")
      $log.info(result)
    ensure
      save_result result
      num_days = $PROPS['PRISME.resched_clean_queue_days'].to_i
      PrismeCleanupJob.set(wait: num_days.days).perform_later
    end

  end
end

# load './app/jobs/clean_job_queue_job.rb'
#c = CleanJobQueueJob.set(wait_until: 2.seconds.from_now).perform_later
