$last_activity_time = 10.years.ago #default last run is 20 years ago, so durations must be 10 years or less.

CACHE_ACTIVITIES = {
    PrismeCacheManager::APP_DEPLOYER => [NexusUtility::DeployerSupport.instance, :can_deploy?],
    PrismeCacheManager::DB_BUILDER => [NexusUtility::DbBuilderSupport.instance, :any_administrator?],
}

CACHE_ACTIVITIES.each_pair do |app, worker|
  worker.first.register
  app_built = PrismeCacheManager::CacheWorkerManager.instance.fetch(app).build_work_thread!
  $log.info("#{app} thread built? #{app_built}")
  $log.error("The Activity worker thread failed to build for #{app}!") unless app_built

  if app_built
    PrismeCacheManager::CacheWorkerManager.instance.fetch(app).work_lock.synchronize do
      $log.always("Broadcasting to #{app}")
      PrismeCacheManager::CacheWorkerManager.instance.fetch(app).wake_up.broadcast #do first time work
    end
  end
end

=begin
NexusUtility::DeployerSupport.instance.get_komet_wars
=end
