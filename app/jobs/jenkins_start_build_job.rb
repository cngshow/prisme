class JenkinsStartBuild < PrismeBaseJob

  PRISME_NAME_PREFIX = 'PRISME_'

  java_import 'com.offbytwo.jenkins.JenkinsServer' do |p, c|
    'JenkinsServer'
  end

  java_import 'java.lang.Exception' do |p, c|
    'JException'
  end

  def perform(*args)
    name = args.shift
    xml = args.shift
    jenkins_url = args.shift
    jenkins_user = args.shift
    jenkins_password = args.shift
    result_hash = {}
    jenkins_config = {url: jenkins_url, user: jenkins_user, password: jenkins_password}
    $log.debug("About to start build #{name} against build server #{jenkins_url}!")
    result = ''

    begin
      jenkins = JenkinsServer.new(java.net.URI.new(jenkins_url), jenkins_user, jenkins_password)
      result << 'Jenkins server created.'
      jenkins.createJob(name, xml, false)
      job = jenkins.getJob(name.strip)
      result << "Jenkins job #{name} created."
      job.build(false)
      $log.debug("#{name} build started")
      result << 'Jenkins build started.'
      time = $PROPS['JENKINS.build_check_seconds'].to_i.seconds
      JenkinsCheckBuild.set(wait: time).perform_later(jenkins_config, name, 1, false, track_child_job)
      $log.debug('Build kicked off!')
    rescue JException => ex
      $log.error("Jenkins Client libraries threw an exception! #{ex}")
      $log.error(ex.backtrace.join("\n"))
      JenkinsCheckBuild.perform_later(jenkins_config, ex.to_s, 1, true, track_child_job)
      raise JenkinsClient::JenkinsJavaError, ex
    ensure
       save_result(result, result_hash)
    end
  end
end
