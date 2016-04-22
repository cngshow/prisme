class JenkinsCheckBuild < PrismeBaseJob

  java_import 'com.offbytwo.jenkins.JenkinsServer' do |p, c|
    'JenkinsServer'
  end


  def perform(*args)
    $log.debug("Check build starting")
    jenkins_config = args.shift
    name = args.shift
    attempt_number = args.shift
    jenkins = JenkinsServer.new(java.net.URI.new(jenkins_config[:url]), jenkins_config[:user], jenkins_config[:password])
    $log.debug("checking stats for #{name}")
  end
end