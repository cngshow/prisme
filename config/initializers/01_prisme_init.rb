$CLASSPATH << "#{Rails.root}/lib/logging"
$CLASSPATH << "#{Rails.root}/lib/rails_common/logging/testLogConfig" if $rake
##
# Do common initialization tasks in prisme
#
jars = Dir.glob('./lib/jars/*.jar')
jars = Dir.glob('./lib/jars/*.jar')
jars.each do |jar|
  require jar
end
require './lib/rails_common/util/rescuable'
require './lib/rails_common/logging/open_logging'
require './lib/rails_common/logging/logging'
require './lib/rails_common/util/helpers'
require './lib/rails_common/logging/prisme_log_event'
require './lib/rails_common/util/bootstrap_notifier' #above roles (roles references these libs)
require './lib/rails_common/roles/roles'

#above from rails common
require './lib/prisme_service'
require './lib/prisme_constants'
require './lib/cipher'
require './lib/jenkin_client'
require './lib/utilities/prisme_utilities'

#System.setProperty("java.util.logging.manager", "org.apache.logging.log4j.jul.LogManager");
props = java.lang.System.getProperties
props.put('java.util.logging.manager', $PROPS['PRISME.log_manager'])
$SERVICE_TYPES = YAML.load_file('./config/service/service_types.yml').freeze

unless ($rake || defined?(Rails::Generators))
  STFU_MODE = false
  begin
    ActiveRecord::Base.logger = $log_rails
    ActiveRecord::Migrator.migrate 'db/migrate'
  rescue => ex
    $log.warn("Migration failed. #{ex.message}")
  ensure
    #ActiveRecord::Base.logger = nil
  end
  $log.info('Migration complete!')

  at_exit do
    unless $testing
      #do cleanup
      $log.always { PrismeLogEvent.notify(PrismeLogEvent::LIFECYCLE_TAG, 'Shutdown called!  Rails Prisme has been ruthlessly executed :-(') }
      if ($database.eql?('H2'))
        begin
          ActiveRecord::Base.connection.execute('SHUTDOWN')
          $log.always('H2 database has been shutdown.')
        rescue => ex
          $log.error('H2 database was not shutdown, or was previously shutdown. ' + ex.message)
          $log.info("If the message above states the database was closed then don't worry :-).")
        end
      else
        #Oracle
        begin
          ActiveRecord::Base.connection.disconnect!
          #ActiveRecord::Base.clear_active_connections!
          #ActiveRecord::Base.clear_all_connections!
          $log.always('Oracle database connections cleared.')
        rescue => ex
          $log.error('Oracle connections were not closed. ' + ex.message)
        end
      end
    end
  end

else
  STFU_MODE = true
end

#https://github.com/jruby/jruby/wiki/PerformanceTuning#dont-enable-objectspace
#one of our dependent gems (zip.rb) enables this.  Disabling.
JRuby.objectspace = false
if (!STFU_MODE || $testing)
  puts 'Object space disabled again'
  require './lib/rails_common/logging/rails_appender'

  #isaac utilities must be loaded after our appenders are set (if they are set.)
  require './lib/isaac_utilities'
  require './lib/hl7_message'
  java_import 'gov.vha.isaac.ochre.api.LookupService' do |p, c|
    'JLookupService'
  end

  at_exit do
    unless $testing
      begin
        $log.info('Internal Isaac libs getting shutdown...')
        JLookupService.shutdownSystem
        $log.info('Isaac is shutdown...')
      rescue => ex
        $log.warn("Isaac libs got cranky during the shutdown. #{ex}")
        $log.warn(ex.backtrace.join("\n"))
      end
    end
  end
end

version = "UNKNOWN"
begin
  version = IO.read('../version.txt')
  $log.always("The version is #{version}")
rescue
  $log.warn("Could not read the version file!")
end
PRISME_VERSION = version
PRISME_ENVIRONMENT = PrismeUtilities.aitc_environment.fetch(Socket.gethostname) rescue 'DEV_BOX'
$log.always { PrismeLogEvent.notify(PrismeLogEvent::LIFECYCLE_TAG, "#{Rails.application.class.parent_name} coming up!  The version is #{PRISME_VERSION}") }
PRISME_NAME = $PROPS['PRISME.application_name']
KOMET_NAME = $PROPS['PRISME.komet_name']
HL7Messaging::init_messaging_engine unless (STFU_MODE || $testing)

# ensure super_user and admin for cboden for demo
=begin
cboden = SsoiUser.find_by_ssoi_user_name('cboden')
cboden.add_role(Roles::SUPER_USER)
cboden.add_role(Roles::ADMINISTRATOR)
=end
