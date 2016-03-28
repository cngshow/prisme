##
# Do common initilization tasks in prisme
#
jars = Dir.glob("./lib/jars/*.jar")
jars.each do |jar|
  require jar
end

require './lib/ets_common/props/prop_loader'
require './lib/ets_common/logging/open_logging'
require './lib/ets_common/logging/logging'

#System.setProperty("java.util.logging.manager", "org.apache.logging.log4j.jul.LogManager");
props = java.lang.System.getProperties
props.put("java.util.logging.manager", $PROPS['PRISME.log_manager'])
