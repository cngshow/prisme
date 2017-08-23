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

    #work tag is something like 'Tomcat_deployments'
    #duration example '10.seconds'
    #dirty lambda, a lambda returning a boolean (if dirty, work occurs independent of time)
    #block is the work to do.
    def register_work(work_tag, duration, dirty_lambda, &block)
      $log.info("Registering #{work_tag} for a duration of #{duration.inspect}")
      @work_lock.synchronize do
        @registered_work << [work_tag, duration, dirty_lambda, block, 20.years.ago]
      end
    end

    def register_work_complete(observer:)
      @notify_complete << observer
    end

    def do_work(asynchronous = true)
      @registered_work.each do |work|
        work_tag = work[0]
        duration = work[1]
        dirty_lambda = work[2]
        block = work[3]
        last_run = work[4]
        $log.trace("Maybe do work #{work_tag}, are we dirty? #{dirty_lambda.call}")#GREG trace
        if (((Time.now - last_run) >= duration) || dirty_lambda.call)
          pool = asynchronous ? @pool : @synchronous
          pool.post do
            @work_lock.synchronize do
              $log.debug("Thread pool about to do work #{work_tag}")#GREG debug
              begin
                block.call
              rescue => ex
                $log.error("#{work_tag} failed to execute! #{ex}")
                $log.error(ex.backtrace.join("\n"))
              end
              work[4] = Time.now
              $log.debug("Work #{work_tag} is complete!")#GREG debug
            end
            @notify_complete.each do |notify|
              begin
                notify.work_complete if notify.respond_to? :work_complete
              rescue => ex
                $log.error("Notification of completion of work failed for #{work_tag}, error: #{ex}")
                $log.error(ex.backtrace.join("\n"))
              end
            end
          end
        else
          $log.trace("Skipping work #{work_tag}")#GREG trace
        end
      end
    end

    def initialize
      @work_lock = Monitor.new
      @registered_work = []
      @notify_complete = []
      @pool = Concurrent::FixedThreadPool.new(1)
      @synchronous = Object.new
      @synchronous.define_singleton_method(:post) do |&block| block.call end
    end
  end

  class ActivitySupport

    attr_accessor :last_activity_time, :dirty

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
      @last_activity_time = 10.years.ago
      @dirty = false
      @dirty_lambda = -> do
        @dirty
      end
    end

    def work_complete
      @dirty = false
      @last_activity_time = Time.now
      $log.debug("#{self} is updating dirty to false! Last activity time is now #{last_activity_time}")#GREG debug
    end

    #overwrite if needed
    def to_s
      self.class.to_s
    end

  end

end

=begin
load('./lib/worker/prisme_cache_manager.rb')

ActivityWorker.instance.register_work('play_work', 5.seconds) do puts "####################################Work #{Time.now}" end

ActivityWorker.instance.work_lock.synchronize do
  ActivityWorker.instance.wake_up.signal #or broadcast
end

$last_activity_time = 10.seconds.from_now

include NexusUtility
DbBuilderSupport.instance
DeployerSupport.instance

=end