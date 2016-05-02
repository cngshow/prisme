class TestJobParent < PrismeBaseJob
  queue_as :default

  def perform(*args)
    $log.info("This job: #{job_id.to_s}")
    # $log.debug("My Parent is #{(arguments.last.is_a? Hash)}" ? arguments.last[:parent_job_id] : 'First call from console!')
    TestJob.set(wait_until: 5.seconds.from_now).perform_later(track_child_job)
  end
end

#job = TestJobParent.set(wait_until: 5.seconds.from_now).perform_later
#job = TestJob.set(wait_until: 1.seconds.from_now).perform_later
# load('./app/jobs/test_job.rb')