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

    def getLevel
      return JCargo::LogLevel::DEBUG if ($log.debug?)
      return JCargo::LogLevel::INFO if ($log.info?)
      return JCargo::LogLevel::WARN #Cargo's max is warn, as all exceptions are simply raised.  So no matter our lewel
                                    #We will at least return warn.
    end

    def setLevel(level)
      #A no op.  We defer to our logger.
    end

    def debug(message, category)
      $log.debug("#{message} -- #{category}}")
    end

    def info(message, category)
      $log.info("#{message} -- #{category}}")
    end

    def warn(message, category)
      $log.warn("#{message} -- #{category}}") if $log.warn?
    end

  end
end
#below moves to active record later
java.lang.System.getProperties.put('cargo.remote.username','devtest')
java.lang.System.getProperties.put('cargo.remote.password','devtest')
java.lang.System.getProperties.put('cargo.tomcat.manager.url','http://vadev.mantech.com:4848/manager')
java.lang.System.getProperties.put('cargo.servlet.port','4848')
java.lang.System.getProperties.put('cargo.hostname','vadev.mantech.com')