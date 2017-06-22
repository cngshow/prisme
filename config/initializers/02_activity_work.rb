require './lib/worker/activity_based_work'
require './lib/utilities/nexus_utility'

$last_activity_time = 10.years.ago #default last run is 20 years ago, so durations must be 10 years or less.

puts "I am here!!!"
NexusUtility::DeployerSupport.instance.register



#last block
ActivityWorker.instance.work_lock.synchronize do
  ActivityWorker.instance.wake_up.broadcast #do first time work
end
puts "bye bye!"

=begin
NexusUtility::DeployerSupport.instance.get_komet_wars
=end