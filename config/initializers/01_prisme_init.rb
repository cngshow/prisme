##
# Do common initilization tasks in prisme
#
jars = Dir.glob("./lib/jars/*.jar")
jars.each do |jar|
  require jar
end

require './lib/rails_common/props/prop_loader'
require './lib/rails_common/logging/open_logging'
require './lib/rails_common/logging/logging'
require './lib/service'
require './lib/cipher'

#System.setProperty("java.util.logging.manager", "org.apache.logging.log4j.jul.LogManager");
props = java.lang.System.getProperties
props.put("java.util.logging.manager", $PROPS['PRISME.log_manager'])
$SERVICE_TYPES = YAML.load_file('./config/service/service_types.yml').freeze
