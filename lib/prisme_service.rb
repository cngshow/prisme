module PrismeService
  TOMCAT = 'tomcat'
  NEXUS = 'nexus'
  JENKINS = 'jenkins'

  # TOMCAT
  CARGO_REMOTE_URL = 'cargo.tomcat.manager.url'
  CARGO_REMOTE_USERNAME = 'cargo.remote.username'
  CARGO_REMOTE_PASSWORD = 'cargo.remote.password'
  CARGO_HOSTNAME = 'vadev.mantech.com'
  CARGO_REMOTE_PORT = 'cargo.remote.port'

  # NEXUS
  NEXUS_ROOT = 'nexus_root'
  NEXUS_USER = 'nexus_user'
  NEXUS_PWD = 'nexus_pwd'

  # JENKINS
  JENKINS_ROOT = 'jenkins_root'
  JENKINS_USER = 'jenkins_user'
  JENKINS_PWD = 'jenkins_pwd'
  JENKINS_XML = './config/service/jenkins_job_config.xml.erb'

  # SERVICE PROPS
  TYPE_PROPS = 'props'
  TYPE_PASSWORD = 'password'
  TYPE_URL = 'url'
  TYPE_NUMBER = 'number'
  TYPE_TYPE = 'type'
  TYPE_KEY = 'key'
  TYPE_VALUE = 'value'
  TYPE_ORDER_IDX = 'order_idx'
end
