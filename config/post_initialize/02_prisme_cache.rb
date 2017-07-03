$last_activity_time = 10.years.ago #default last run is 20 years ago, so durations must be 10 years or less.

CACHE_ACTIVITIES = {
    #the pattern:
    #PrismeCacheManager::Some_Cache_Constant => [[work for registration 1, work for registration 2, ...], :roles_symbol?] (or nil if no roles are required)
    PrismeCacheManager::APP_DEPLOYER => [[
                                             NexusUtility::DeployerSupport.instance,
                                         ], :can_deploy?],
    PrismeCacheManager::DB_BUILDER => [[
                                           NexusUtility::DbBuilderSupport.instance,
                                       ], :any_administrator?],
    PrismeCacheManager::TOMCAT_DEPLOY => [[
                                              TomcatUtility::TomcatDeploymentsCache.instance,
                                       ], nil]
}

begin
  CACHE_ACTIVITIES.each_pair do |app, worker|
    worker.first.each do |e| e.register end
    PrismeCacheManager::CacheWorkerManager.instance.fetch(app).do_work
  end
rescue => ex
  $log.error("Failure in generating activity cache.. #{ex}")
  $log.error(ex.backtrace.join("\n"))
end

=begin
NexusUtility::DeployerSupport.instance.get_komet_wars
include NexusUtility
DbBuilderSupport.instance
DeployerSupport.instance
=end
