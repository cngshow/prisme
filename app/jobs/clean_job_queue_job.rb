class CleanJobQueueJob < PrismeBaseJob
  queue_as :default

  def perform(*args)
    params = [$PROPS['PRISME.job_queue_trim'].to_i.days.ago,
              PrismeJobConstants::Status::COMPLETED,
              PrismeJobConstants::Status::FAILED,
    ]

    # delete all jobs that are x days old
    cnt = PrismeJob.delete_all(['completed_at < ? AND (status = ? OR status= ?)', *params])
    $log.info("CleanJobQueueJob deleted #{cnt} records from the prisme_jobs table.")

    # schedule this job to run again one day from now
    num_days = $PROPS['PRISME.resched_clean_queue_days'].to_i
    CleanJobQueueJob.set(wait: num_days.days).perform_later
  end
end

# load './app/jobs/clean_job_queue_job.rb'
#c = CleanJobQueueJob.set(wait_until: 2.seconds.from_now).perform_later
