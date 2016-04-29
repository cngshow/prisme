class TestJob < PrismeBaseJob
  queue_as :default
  @@runs = 0

  def perform(*args)
    $log.info("This job: #{job_id.to_s}")
    # $log.debug("My Parent is #{(arguments.last.is_a? Hash)}" ? arguments.last[:parent_job_id] : 'First call from console!')
    @@runs += 1
    TestJob.set(wait_until: 5.seconds.from_now).perform_later(track_child_job) unless @@runs == 4

    if @@runs == 4
      $log.info("BAILING OUT!!!!: #{job_id.to_s}")
      @@runs = 0
    end
  end
end

#job = TestJob.set(wait_until: 30.seconds.from_now).perform_later
#job = TestJob.set(wait_until: 1.seconds.from_now).perform_later
#job = TestJob.perform_now
#
# load('./app/jobs/test_job.rb')