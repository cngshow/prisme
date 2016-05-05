##
# Do common initialization tasks in prisme
#
jars = Dir.glob('./lib/jars/*.jar')
jars.each do |jar|
  require jar
end

require './lib/rails_common/props/prop_loader'
require './lib/rails_common/logging/open_logging'
require './lib/rails_common/logging/logging'
require './lib/prisme_service'
require './lib/cipher'
require './lib/jenkin_client'
$log.always("Prisme is coming up.")
#System.setProperty("java.util.logging.manager", "org.apache.logging.log4j.jul.LogManager");
props = java.lang.System.getProperties
props.put('java.util.logging.manager', $PROPS['PRISME.log_manager'])
$SERVICE_TYPES = YAML.load_file('./config/service/service_types.yml').freeze


at_exit do
  #do cleanup
  begin
    $log.always("Shutdown called!  Rails Prisme has been ruthlessly executed :-(" )
    ActiveRecord::Base.connection.execute("SHUTDOWN")
    $log.always("H2 database has been shutdown.")
  rescue => ex
    $log.error("H2 database was not shutdown, or was previously shutdown. " + ex.message)
    $log.info("If the message above states the database was closed then don't worry :-).")
  end
end