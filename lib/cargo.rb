java_import 'org.codehaus.cargo.util.log.Logger' do |p,c|
  "JCargoLogger"
end

module JCargo
  include_package 'org.codehaus.cargo.generic'
  include_package 'org.codehaus.cargo.container'
  include_package 'org.codehaus.cargo.container.configuration'
  include_package 'org.codehaus.cargo.container.tomcat'
  include_package 'org.codehaus.cargo.container.deployable'
  include_package 'org.codehaus.cargo.container.deployer'
  include_package 'org.codehaus.cargo.generic.deployable'
  include_package 'org.codehaus.cargo.util.log'
end

module CargoSupport
  class CargoLogger
    include JCargoLogger

    attr_reader :results

    def initialize
      @results = String.new
    end

    def getLevel
      return JCargo::LogLevel::DEBUG #always return debug so we capture all of Cargo's chatter for the job result.
      # return JCargo::LogLevel::INFO if ($log.info?)
      # return JCargo::LogLevel::WARN #Cargo's max is warn, as all exceptions are simply raised.  So no matter our lewel
      #                               #We will at least return warn.
    end

    def setLevel(level)
      #A no op.  We defer to our logger.
    end

    def debug(message, category)
      @results << "debug: #{message} -- #{category}\n"
      $log.debug("#{message} -- #{category}}")
    end

    def info(message, category)
      @results << "info: #{message} -- #{category}\n"
      $log.info("#{message} -- #{category}}")
    end

    def warn(message, category)
      @results << "warn: #{message} -- #{category}\n"
      $log.warn("#{message} -- #{category}}")
    end

  end
end
#below moves to active record later (service libraries)
java.lang.System.getProperties.put('cargo.remote.username','devtest')
java.lang.System.getProperties.put('cargo.remote.password','devtest')
java.lang.System.getProperties.put('cargo.tomcat.manager.url','http://vadev.mantech.com:4848/manager')
java.lang.System.getProperties.put('cargo.servlet.port','4848')
java.lang.System.getProperties.put('cargo.hostname','vadev.mantech.com')