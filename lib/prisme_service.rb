module PrismeService
  TOMCAT = 'tomcat'
  NEXUS = 'nexus'
  JENKINS = 'jenkins'
  GIT = 'git'

  # TOMCAT
  CARGO_REMOTE_URL = 'cargo.tomcat.manager.url'
  CARGO_REMOTE_USERNAME = 'cargo.remote.username'
  CARGO_REMOTE_PASSWORD = 'cargo.remote.password'

  # NEXUS
  NEXUS_ROOT = 'nexus_root'
  NEXUS_REPOSITORY_URL = 'nexus_repository_url'
  NEXUS_USER = 'nexus_user'
  NEXUS_PWD = 'nexus_pwd'

  # JENKINS
  JENKINS_ROOT = 'jenkins_root'
  JENKINS_USER = 'jenkins_user'
  JENKINS_PWD = 'jenkins_pwd'
  JENKINS_XML = './config/service/jenkins_job_config.xml.erb'

  # git
  GIT_ROOT = 'git_root'
  GIT_REPOSITORY_URL = 'git_repository_url'
  GIT_USER = 'git_user'
  GIT_PWD = 'git_pwd'

  # SERVICE PROPS
  TYPE_PROPS = 'props'
  TYPE_PASSWORD = 'password'
  TYPE_URL = 'url'
  TYPE_NUMBER = 'number'
  TYPE_TYPE = 'type'
  TYPE_KEY = 'key'
  TYPE_TOOLTIP = 'tooltip'
  TYPE_VALUE = 'value'
  TYPE_ORDER_IDX = 'order_idx'
end
