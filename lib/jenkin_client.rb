module JenkinsClient
  #finds all jobs starting with PRISME_ and whack them
  def clean_up_old_jobs
    props = Service.get_build_server_props
    url = props[PrismeService::JENKINS_ROOT]
    user = props[PrismeService::JENKINS_USER]
    password = props[PrismeService::JENKINS_PWD]
    prefix = JenkinsStartBuild::PRISME_NAME_PREFIX
    jenkins = JenkinsServer.new(java.net.URI.new(url), user, password)
    jobs_map = jenkins.getJobs
    deleted = []
    $log.debug("clean_up_old_jobs ")
    $log.debug(jobs_map.inspect) unless jobs_map.nil?
    jobs_map.each_pair do |name, job|
      $log.debug(name)
      if (name.starts_with?(prefix, prefix.downcase))#this api seems to lose the case of the Job...
        result = " deleted."
        begin
          build = job.getLastCompletedBuild
            #jenkins.deleteJob(name, false) unless build.nil?
            $log.info("Deleted #{name}") unless build.nil?
        rescue => ex
          result = " not deleted."
          $log.warn("Attempt to delete Jenkins job named #{name} failed! Message: " + ex.message)
        end

        deleted << name + result
        $log.info("Jenkins job #{name} was #{result}!") unless build.nil?
      end
    end
    deleted
  end

  class JenkinsJavaError < StandardError
  end

end