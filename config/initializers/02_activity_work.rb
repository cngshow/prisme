require './lib/worker/activity_based_work'
require './lib/utilities/nexus_utility'

$last_activity_time = 10.years.ago #default last run is 20 years ago, so durations must be 10 years or less.

NexusUtility::DeployerSupport.instance.register



#last block
PrismeActivity::ActivityWorkManager.instance.fetch(PrismeActivity::APP_DEPLOYER).work_lock.synchronize do
  PrismeActivity::ActivityWorkManager.instance.fetch(PrismeActivity::APP_DEPLOYER).wake_up.broadcast #do first time work
end

=begin
NexusUtility::DeployerSupport.instance.get_komet_wars
=end