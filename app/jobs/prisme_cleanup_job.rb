class PrismeCleanupJob < PrismeBaseJob
  queue_as :default
  def default_user
    PrismeJobConstants::User::SYSTEM
  end

  def perform(*args)
    $log.info("cleaning #{self}")
    first_run = args.shift
    params = [$PROPS['PRISME.job_queue_trim'].to_i.days.ago,
              PrismeJobConstants::Status::STATUS_HASH[:COMPLETED],
              PrismeJobConstants::Status::STATUS_HASH[:FAILED],
              PrismeJobConstants::Status::STATUS_HASH[:ORPHANED],
    ]
    # delete all jobs that are x days old
    cnt = PrismeJob.delete_all(['completed_at < ? AND (status = ? OR status= ? OR status=?)', *params])
    result = "PrismeCleanupJob deleted #{cnt} old records from the prisme_jobs table.\n"
    $log.info(result)
    result = ""
    $log.debug("My id is #{job_id}")
    begin
      if first_run
        PrismeJob.tag_orphans(job_id)
      end

      # schedule this job to run again one day from now
      status = nil
      begin
        status = JenkinsClient::clean_up_old_jobs
      rescue => ex
        $log.warn("There was a failure while deleting some old jenkins jobs.  If some of them were active this is a normal condition.")
        $log.warn("The error was " + ex.message)
      end
      result = status.join("\n") unless status.nil?
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
