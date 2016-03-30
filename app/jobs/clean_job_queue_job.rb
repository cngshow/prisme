class CleanJobQueueJob < PrismeBaseJob
  queue_as :default

  def default_user
    PrismeJobConstants::User::SYSTEM
  end

  def perform(*args)
    params = [$PROPS['PRISME.job_queue_trim'].to_i.days.ago,
              PrismeJobConstants::Status::COMPLETED,
              PrismeJobConstants::Status::FAILED,
    ]

    # delete all jobs that are x days old
    cnt = PrismeJob.delete_all(['completed_at < ? AND (status = ? OR status= ?)', *params])
    result = "CleanJobQueueJob deleted #{cnt} old records from the prisme_jobs table.\n"
    $log.info(result)
    active_record = lookup
    active_record.result= result
    active_record.save!
    # schedule this job to run again one day from now
    num_days = $PROPS['PRISME.resched_clean_queue_days'].to_i
    CleanJobQueueJob.set(wait: num_days.days).perform_later
  end
end

# load './app/jobs/clean_job_queue_job.rb'
#c = CleanJobQueueJob.set(wait_until: 2.seconds.from_now).perform_later
