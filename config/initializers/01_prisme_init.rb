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

# ArJdbc::ConnectionMethods.h2_connection({:adapter=>"jdbch2", :database=>"db/data/h2_prisme_test"})
at_exit do
  #do cleanup
  current_cl = nil
  begin
    # $log.always("Shutdown called!  Rails Prisme has been ruthlessly executed :-( " )
    # one = java.lang.Class.forName(org.h2.Driver.java_class.to_java.getName,true,org.h2.Driver.java_class.to_java.getClassLoader)
    # $log.always("one is #{one}")
    # two =  java.lang.Class.forName("org.h2.Driver")
    # $log.always("two is #{two}")
    # current_cl =  java.lang.Thread.currentThread.getContextClassLoader
    # h2_loader = org.h2.Driver.java_class.to_java.getClassLoader
    # java.lang.Thread.currentThread.setContextClassLoader(h2_loader)
    ActiveRecord::Base.clear_active_connections!
    $log.always("Active connections cleared")
    config   = Rails.configuration.database_configuration
    url = config[Rails.env]["database"]
    url = 'jdbc:h2:./' + url
    $log.always(url)
    con = java.sql.DriverManager.getConnection(url,'sa','')
    s = con.createStatement
    s.executeUpdate("SHUTDOWN")
    $log.always("H2 database has been shutdown.")
  rescue => ex
    $log.error("H2 database was not shutdown. " + ex.message)
  ensure
    #java.lang.Thread.currentThread.setContextClassLoader(current_cl)
  end
end