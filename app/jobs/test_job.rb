class TestJob < PrismeBaseJob
  queue_as :default

  def perform(*args)
    $log.info("This job: " + job_id.to_s)
    #$log.debug("My Parent " + parent_id.to_s)
    track_parent(TestJob.set(wait_until: 5.seconds.from_now).perform_later)
    #do other shit
  end
end

#job = TestJob.set(wait_until: 5.seconds.from_now).perform_later
#job = TestJob.set(wait_until: 1.seconds.from_now).perform_later
# load('./app/jobs/test_job.rb')