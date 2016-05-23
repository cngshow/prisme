require './lib/cargo'
require 'fileutils'

class DeployWarJob < PrismeBaseJob

  @@mutex = Mutex.new

  def perform(*args)
    begin
      logger = CargoSupport::CargoLogger.new
      file_name = args.shift
      context = args.shift
      tomcat_ar = args.shift

      unless (context.nil?)
        file_type = File.extname(file_name)
        file_dir = File.dirname(file_name)
        new_file = file_dir + context + file_type
        FileUtils.cp(file_name, new_file)
        file_name = new_file
      end

      factory = JCargo::DefaultContainerFactory.new
      type = JCargo::ContainerType::REMOTE
      runtime_config = JCargo::TomcatRuntimeConfiguration.new
      props = tomcat_ar.properties_hash
      props.each_pair do |k, v|
        #cargo.hostname = localhost everytime
        #cargo.servlet.port = localhost everytime
        runtime_config.setProperty(k, v)
        $log.debug("Added #{k} -- #{v} to the runtime config.")
      end
      tom_container = factory.createContainer("tomcat8x", type, runtime_config)
      deployable_type = JCargo::DeployableType::WAR
      deployer_factory = JCargo::DefaultDeployableFactory.new
      remote_container = JCargo::Tomcat8xRemoteContainer.new(runtime_config)
      deployer = JCargo::Tomcat8xRemoteDeployer.new(remote_container)
      deployer.setLogger(logger)
      #to_do: pull string below from ActiveRecord
      #url.registerListener(DeployListener.new)
      war = deployer_factory.createDeployable(tom_container.getId(), file_name, deployable_type);
      #to_do -- switch to undeploy/redeploy
      $log.info("About to deploy #{file_name}")
      #only allow one deployment at a time.TomcatRuntimeConfiguration
      #The user will see their job as running, but, since cargo was engineered for maven and communicates via props
      #we cannot have a user selecting a different tomcat motivating deployment to the wrong server.
      url = JCargo::URLDeployableMonitor.new(java.net.URL.new(props[PrismeService::CARGO_REMOTE_URL])) #("http://vadev.mantech.com:4848/"))
      url.setLogger(logger)
      deployer.redeploy(war, url)
      $log.info("Deployed #{file_name}")
    rescue => ex
      $log.error("A Java Exception was thrown: #{ex.message}")
      $log.error(ex.backtrace.join("\n"))
      raise CargoSupport::CargoError.new(ex.message)
    ensure
      results = logger.results
      results << "Deployed #{file_name}\n"
      save_result results
    end
  end
end
#below moves to active record later (service libraries)
# java.lang.System.getProperties.put('cargo.remote.username', 'devtest')
# java.lang.System.getProperties.put('cargo.remote.password', 'devtest')
# java.lang.System.getProperties.put('cargo.tomcat.manager.url', 'http://vadev.mantech.com:4848/manager')
# java.lang.System.getProperties.put('cargo.servlet.port', '4848')
# java.lang.System.getProperties.put('cargo.hostname', 'vadev.mantech.com')