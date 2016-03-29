require './lib/cargo'

class DeployWarJob < PrismeBaseJob

  def perform(*args)
    logger = CargoSupport::CargoLogger.new
    file_name = args.shift
    context = args.shift
    factory = JCargo::DefaultContainerFactory.new
    type = JCargo::ContainerType::REMOTE
    runtime_config = JCargo::TomcatRuntimeConfiguration.new
    tom_container = factory.createContainer("tomcat8x", type, runtime_config)
    deployable_type = JCargo::DeployableType::WAR
    deployer_factory = JCargo::DefaultDeployableFactory.new
    remote_container = JCargo::Tomcat8xRemoteContainer.new(runtime_config)
    deployer = JCargo::Tomcat8xRemoteDeployer.new(remote_container)
    deployer.setLogger(logger)
    #to_do: pull string below from ActiveRecord
    url = JCargo::URLDeployableMonitor.new(java.net.URL.new("http://vadev.mantech.com:4848/"))
    #url.registerListener(DeployListener.new)
    url.setLogger(logger)
    war = deployer_factory.createDeployable(tom_container.getId(), file_name, deployable_type);
    $log.info("About to deploy #{file_name}")
    #to_do -- switch to undeploy/redeploy
    deployer.deploy(war, url)
    $log.info("Deployed #{file_name}")
  end
end
