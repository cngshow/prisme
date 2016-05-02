java_import 'com.offbytwo.jenkins.JenkinsServer' do |p, c|
  'JenkinsServer'
end

java_import 'com.offbytwo.jenkins.model.BuildResult' do |p, c|
  'JBuildResult'
end


module JenkinsClient
  #finds all jobs starting with PRISME_ and whack them
  def self.clean_up_old_jobs
    props = Service.get_build_server_props
    url = props[PrismeService::JENKINS_ROOT]
    user = props[PrismeService::JENKINS_USER]
    password = props[PrismeService::JENKINS_PWD]
    prefix = JenkinsStartBuild::PRISME_NAME_PREFIX
    jenkins = JenkinsServer.new(java.net.URI.new(url), user, password)
    jobs_map = jenkins.getJobs
    deleted = []
    $log.debug("clean_up_old_jobs")
    #$log.debug(jobs_map.inspect) unless jobs_map.nil?
    build, dont_delete_me = nil
    jobs_map.each_pair do |name, job|
      # $log.debug(name)
      if (name.starts_with?(prefix, prefix.downcase)) #this api seems to lose the case of the Job...
        $log.debug("#{name} is a candidate for deletion.")
        result = " deleted."
        begin
          job = jenkins.getJob(name.strip) #the map doesn't have a job detail, re-fetch.
          build = job.getLastBuild.details.getResult
          dont_delete_me = (build.equals(JBuildResult::REBUILDING) || build.equals(JBuildResult::NOT_BUILT))
          unless dont_delete_me
            jenkins.deleteJob(name, false)
            $log.info("Deleted #{name}")
          end
        rescue java.lang.Exception => ex
          result = " not deleted."
          $log.warn("Attempt to delete Jenkins job named #{name} failed! Message: " + ex.message)
        end
        unless dont_delete_me
          deleted << name + result
          $log.info("Jenkins job #{name} was #{result}")
        end
      end
    end
    deleted
  end

  class JenkinsJavaError < StandardError
  end

end