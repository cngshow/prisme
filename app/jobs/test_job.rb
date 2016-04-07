class TestJob < PrismeBaseJob
  queue_as :default

  def perform(*args)
    $log.info("This job: is dun!!")
  end
end

#job = TestJob.set(wait_until: 5.seconds.from_now).perform_later
#job = TestJob.set(wait_until: 1.seconds.from_now).perform_later