##
# Do common initialization tasks in prisme
#
jars = Dir.glob('./lib/jars/*.jar')
jars.each do |jar|
  require jar
end
#from rails common
require './lib/rails_common/props/prop_loader'
require './lib/rails_common/logging/open_logging'
require './lib/rails_common/logging/logging'
#above from rails common

require './lib/prisme_service'
require './lib/cipher'
require './lib/jenkin_client'
require './lib/rails_common/util/helpers'
require './lib/isaac_git_utilities'
require './lib/rails_common/roles/roles'

#System.setProperty("java.util.logging.manager", "org.apache.logging.log4j.jul.LogManager");
props = java.lang.System.getProperties
props.put('java.util.logging.manager', $PROPS['PRISME.log_manager'])
$SERVICE_TYPES = YAML.load_file('./config/service/service_types.yml').freeze

unless ($rake || defined?(Rails::Generators))

  begin
    ActiveRecord::Base.logger = $log if (boolean($PROPS['PRISME.log_active_record']))
    ActiveRecord::Migrator.migrate "db/migrate"
  rescue => ex
    $log.warn("Migration failed. #{ex.message}")
  ensure
    #ActiveRecord::Base.logger = nil
  end
  $log.info("Migration complete!")

  at_exit do
    #do cleanup
    begin
      $log.always("Shutdown called!  Rails Prisme has been ruthlessly executed :-(")
      ActiveRecord::Base.connection.execute("SHUTDOWN")
      $log.always("H2 database has been shutdown.")
    rescue => ex
      $log.error("H2 database was not shutdown, or was previously shutdown. " + ex.message)
      $log.info("If the message above states the database was closed then don't worry :-).")
    end
  end
end