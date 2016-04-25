class JenkinsStartBuild < PrismeBaseJob

  PRISME_NAME_PREFIX = "PRISME_"

  java_import 'com.offbytwo.jenkins.JenkinsServer' do |p, c|
    'JenkinsServer'
  end

  java_import 'java.lang.Exception' do |p, c|
    'JException'
  end

  def perform(*args)
    name = args.shift
    xml = args.shift
    url = args.shift
    user = args.shift
    password = args.shift
    jenkins_config = {url: url, user: user, password: password}
    $log.debug("About to start build #{name} against build server #{url}!")
    result = ""
    begin
      jenkins = JenkinsServer.new(java.net.URI.new(url), user, password)
      result << "Jenkins server created."
      jenkins.createJob(name, xml, false)
      job = jenkins.getJob(name.strip)
      result << "Jenkins job #{name} created."
      job.build(false)
      $log.debug("#{name} build started")
      result << "Jenkins build started."
      time = $PROPS['JENKINS.build_check_seconds'].to_i.seconds
      JenkinsCheckBuild.set(wait: time).perform_later(jenkins_config, name, 1)
      $log.debug("Build kicked off!")
    rescue JException => ex
      $log.error("Jenkins Client libraries threw an exception! #{ex}")
      $log.error(ex.backtrace.join("\n"))
      raise JenkinsClient::JenkinsJavaError, ex
    ensure
      save_result result
    end
  end

end
