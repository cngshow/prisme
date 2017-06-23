module PrismeActivity

  APP_DEPLOYER = :app_deployer

  class ActivityWorkManager
    include Singleton

    def fetch(symbol)
      raise ArgumentError("Argument must be a symbol!") unless symbol.is_a? Symbol
      @build_lock.synchronize do
        return @work_map[symbol] if @work_map[symbol]
        w = PrismeActivity::ActivityWorker.new
        @work_map[symbol] = w
        w
      end
    end

    def initialize
      @work_map = {}
      @build_lock = Mutex.new
    end
  end

  class ActivityWorker
    attr_reader :work_lock
    attr_reader :wake_up

    def register_work(work_tag, duration, &block)
      $log.info("Registering #{work_tag} for a duration of #{duration.inspect}")
      @work_lock.synchronize do
        @registered_work << [work_tag, duration, block, 20.years.ago]
      end
    end

    def build_work_thread!
      return false if @work_thread&.alive?
      @work_thread = Thread.new do
        @work_lock.synchronize do
          while (true) do
            begin
              @wake_up.wait
              @registered_work.each do |work|
                begin
                  work_tag = work[0]
                  duration = work[1]
                  block = work[2]
                  last_run = work[3]
                  if (($last_activity_time - last_run) >= duration)
                    $log.debug("About to do work #{work_tag}")
                    block.call
                    work[3] = Time.now
                    $log.debug("Work #{work_tag} is complete!")
                  else
                    $log.debug("Skipping work #{work_tag}")
                  end
                rescue => ex
                  $log.error("#{work_tag} failed to execute! #{ex}")
                  $log.error(ex.backtrace.join("\n"))
                end
              end
            rescue => ex
              $log.error("Work thread error! #{ex}")
              $log.error(ex.backtrace.join("\n"))
            end
          end
        end
      end
      true
    end

    def initialize
      @work_lock = Monitor.new
      @wake_up = Monitor::ConditionVariable.new(@work_lock)
      @registered_work = []
    end
  end
end


app_built = PrismeActivity::ActivityWorkManager.instance.fetch(PrismeActivity::APP_DEPLOYER).build_work_thread!
$log.info("AppDeployer thread built? #{app_built}")
$log.error("The Activity worker thread failed to build!") unless app_built
=begin
load('./lib/worker/activity_based_work.rb')

ActivityWorker.instance.register_work('play_work', 5.seconds) do puts "####################################Work #{Time.now}" end

ActivityWorker.instance.work_lock.synchronize do
  ActivityWorker.instance.wake_up.signal #or broadcast
end

$last_activity_time = 10.seconds.from_now

=end