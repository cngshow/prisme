module PrismeCacheManager

  APP_DEPLOYER = :app_deployer
  DB_BUILDER = :db_builder
  TOMCAT_DEPLOY = :tomcat_deploy

  class CacheWorkerManager
    include Singleton

    def fetch(symbol)
      raise ArgumentError('Argument must be a symbol!') unless symbol.is_a? Symbol
      @build_lock.synchronize do
        return @work_map[symbol] if @work_map[symbol]
        w = PrismeCacheManager::CacheWorker.new
        @work_map[symbol] = w
        w
      end
    end

    def initialize
      @work_map = {}
      @build_lock = Mutex.new
    end
  end

  class CacheWorker
    attr_reader :work_lock

    def register_work(work_tag, duration, &block)
      $log.info("Registering #{work_tag} for a duration of #{duration.inspect}")
      @work_lock.synchronize do
        @registered_work << [work_tag, duration, block, 20.years.ago]
      end
    end

    def do_work
      @registered_work.each do |work|
        work_tag = work[0]
        duration = work[1]
        block = work[2]
        last_run = work[3]
        $log.trace("Maybe do work #{work_tag}")
        if (($last_activity_time - last_run) >= duration)
          @pool.post do
            @work_lock.synchronize do
              $log.debug("Thread pool about to do work #{work_tag}")
              begin
                block.call
              rescue => ex
                $log.error("#{work_tag} failed to execute! #{ex}")
                $log.error(ex.backtrace.join("\n"))
              end
              work[3] = Time.now
              $log.debug("Work #{work_tag} is complete!")
            end
          end
        else
          $log.trace("Skipping work #{work_tag}")
        end
      end
    end

    def initialize
      @work_lock = Monitor.new
      @registered_work = []
      @pool = Concurrent::FixedThreadPool.new(1)
    end
  end

  class ActivitySupport
    def atomic_fetch(*fetches)
      @work_lock.synchronize do
        hash = {}
        fetches.each do |fetch|
          fetch = fetch.to_s.to_sym
          hash[fetch] = self.send(fetch) if self.respond_to? fetch
        end
        hash
      end
    end

    def initialize(lock)
      @work_lock = lock
    end
  end

end

=begin
load('./lib/worker/activity_based_work.rb')

ActivityWorker.instance.register_work('play_work', 5.seconds) do puts "####################################Work #{Time.now}" end

ActivityWorker.instance.work_lock.synchronize do
  ActivityWorker.instance.wake_up.signal #or broadcast
end

$last_activity_time = 10.seconds.from_now

include NexusUtility
DbBuilderSupport.instance
DeployerSupport.instance

=end