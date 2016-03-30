require './app/jobs/prisme_base_job'
require 'sucker_punch/async_syntax'
SuckerPunch.logger = $log

java_import 'java.util.Timer' do |p, c|
  'JTimer'
end

java_import 'java.util.TimerTask' do |p, c|
  'JTimerTask'
end

class TimerTask < JTimerTask

  def set_runnable(task_lambda)
    @lamb = task_lambda
  end

  def run
    @lamb.call
  end

end
# irb(main):011:0> TimerTask.new.to_java.getClass.getSuperclass
# => class java.util.TimerTask

module ActiveJob
  module QueueAdapters
    class SuckerPunchAdapter
      class << self
        def enqueue_at(job, timestamp) #:nodoc:
          time = java.util.Date.new(timestamp * 1000)
          timer = JTimer.new(job.to_s)
          timer_task = TimerTask.new
          timer_task.set_runnable(-> { JobWrapper.new.async.perform job.serialize })
          timer.java_send(:schedule, [JTimerTask.java_class, java.util.Date.java_class], timer_task, time)
        end
      end
    end
  end
end


unless defined?(is_running_migration_or_rollback?) && is_running_migration_or_rollback?
# update any uncompleted jobs that are in the PrismeJobs table to failure status
  params = [PrismeJobConstants::Status::STATUS_HASH[:COMPLETED],
            PrismeJobConstants::Status::STATUS_HASH[:FAILED],]
  update_hash = {status: PrismeJobConstants::Status::STATUS_HASH[:FAILED], last_error: 'System Failure - Incompleted job update to Failed in initializer!'}
  PrismeJob.where(['status != ? and status != ?', *params]).update_all(update_hash)

# schedule the CleanJobQueueJob to run soon
  CleanJobQueueJob.perform_later
end

