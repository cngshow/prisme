require './app/jobs/prisme_base_job'
Dir['./app/jobs/*.rb'].each { |file| require file }

require 'sucker_punch/async_syntax'

module ActiveJob
  module QueueAdapters
    class SuckerPunchAdapter
      class << self
        def enqueue_at(job, timestamp)
          #current_name = java.lang.Thread.currentThread.getName
          #java.lang.Thread.currentThread.setName("Prisme Scheduled Job #{job}")
          @@scheduler ||= java.util.concurrent.Executors.newScheduledThreadPool(20, JIsaacLibrary::NamedThreadFactory.new('PrismeScheduler', true))
          time_delay = [timestamp - Time.now.to_i, 0].max #java source code (for one impl) does this already, but to be safe...)
          @@scheduler.schedule(-> { JobWrapper.new.async.perform job.serialize }, time_delay, java.util.concurrent.TimeUnit::SECONDS);
        end

        def shutdown_scheduler
          begin
            $log.info("Preparing to shutdown future scheduler")
            @@scheduler.shutdownNow
            bool = @@scheduler.awaitTermination(10, java.util.concurrent.TimeUnit::SECONDS)
            unless bool
              $log.warn("The scheduler failed to be stopped via shutdownNow in ten seconds.")
              $log.warn("#{naughty_tasks}")
            end
            $log.info("Scheduler stopped!")
          rescue => ex
            $log.error("I could not shut down the scheduler for active job. #{ex}")
            $log.error(ex.backtrace.join("\n"))
          end
        end
      end
    end
  end
end

at_exit do
  ActiveJob::QueueAdapters::SuckerPunchAdapter.shutdown_scheduler unless $testing
end

unless ($rake || defined?(Rails::Generators))
  #schedule the PrismeCleanupJob to run now, synchronously in the current thread.
  PrismeCleanupJob.perform_now(true)
end
