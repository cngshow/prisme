java_import 'com.offbytwo.jenkins.JenkinsServer' do |p, c|
  'JenkinsServer'
end

java_import 'com.offbytwo.jenkins.model.BuildResult' do |p, c|
  'JBuildResult'
end


class JenkinsCheckBuild < PrismeBaseJob
  class Deleted
    UNKNOWN = 'unknown'
    YES = 'yes'
    NO = 'no'
  end
  class BuildResult
    INQUEUE = "INQUEUE"
    BUILDING = JBuildResult::BUILDING.to_s
    FAILURE = JBuildResult::FAILURE.to_s
    UNSTABLE = JBuildResult::UNSTABLE.to_s
    REBUILDING = JBuildResult::REBUILDING.to_s
    BUILDING = JBuildResult::BUILDING.to_s
    ABORTED = JBuildResult::ABORTED.to_s
    SUCCESS = JBuildResult::SUCCESS.to_s
    UNKNOWN = JBuildResult::UNKNOWN.to_s
    NOT_BUILT = JBuildResult::NOT_BUILT.to_s
  end

  def perform(*args)
    $log.info("Check build starting")
    jenkins_config = args.shift
    name = args.shift
    attempt_number = args.shift
    max_attempts = $PROPS['JENKINS.max_health_checks'].to_i
    $log.info("checking stats for #{name}")
    attempt_number = args.shift
    time = $PROPS['JENKINS.build_check_seconds'].to_i.seconds
    jenkins, jenkins_job, build, details, build_result = nil
    result = String.new
    result_hash = {}
    result_hash[:name] = name.strip
    result_hash[:attempt_number] = attempt_number
    result_hash[:deleted] = Deleted::NO
    begin
      jenkins = JenkinsServer.new(java.net.URI.new(jenkins_config[:url]), jenkins_config[:user], jenkins_config[:password])
      jenkins_job = jenkins.getJob(name.strip)
      result << "Jenkins job #{name} was fetched from Jenkins.\n"
      build = jenkins_job.getLastBuild()
      if (build.nil?)
        #we are still in the queue handle this
        $log.info("#{name} is still in Jenkin's queue.")
        result << "Jenkins job #{name} is in the build queue.\n"
        result_hash[:build] = BuildResult::INQUEUE
        JenkinsCheckBuild.set(wait: time).perform_later(jenkins_config, name, attempt_number, track_child_job)
      else
        details = build.details #can throw NPE even though build is not nil
        if (details.isBuilding)
          #we are building handle this
          result_hash[:build] = BuildResult::BUILDING
          result << "Jenkins job #{name} is still building.\n"
          $log.info("#{name} is still being built by Jenkins.")
          JenkinsCheckBuild.set(wait: time).perform_later(jenkins_config, name, attempt_number, track_child_job)
        else
          #set the result
          build_result = details.getResult
          if (build_result == JBuildResult::REBUILDING)
            result << "Jenkins job #{name} is rebuilding.\n"
            result_hash[:build] = build_result.to_s
            #do rebuilding
            JenkinsCheckBuild.set(wait: time).perform_later(jenkins_config, name, attempt_number, track_child_job)
          else
            #display the result and delete the job
            result << "Jenkins job #{name} has a build result of " + build_result.to_s + ".\n"
            $log.info "Jenkins job #{name} has a build result of " + build_result.to_s + ".\n"
            result_hash[:build] = build_result.to_s
            begin
              result_hash[:deleted] = Deleted::UNKNOWN
              jenkins.deleteJob(name.strip, false)
              result_hash[:deleted] = Deleted::YES
              result << " Jenkins job #{name} was deleted from Jenkins.\n"
              $log.info " Jenkins job #{name} was deleted from Jenkins.\n"
            rescue java.lang.Exception => ex
              #https://github.com/RisingOak/jenkins-client/issues/154
              #we just log this.  Cleanup Job will take a second crack at it if needed
              $log.warn("Deletion of Jenkins job named #{name} may have failed.")
              $log.warn("Error message is: " + ex.message)
            end
          end
        end
      end
    rescue java.lang.Exception => ex
      #something went wrong.  Increment attempt count and retry if appropriate.
      $log.error("Unable to get the build status of #{name}.  Message: " + ex.message)
      attempt_number += 1
      result_hash[:attempt_number] = attempt_number
      if (attempt_number <= max_attempts)
        $log.info("Attempting to gain the status of #{name} again.")
        JenkinsCheckBuild.set(wait: time).perform_later(jenkins_config, name, attempt_number)
        raise JenkinsClient::JenkinsJavaError, ex
      end
    ensure
      save_result result, result_hash
    end
  end

  def self.build_result(ar)
    result_hash(ar)[:build.to_s]
  end

  def self.jenkins_job_name(ar)
    result_hash(ar)[:name.to_s]
  end

  def self.attempt_number(ar)
    result_hash(ar)[:attempt_number.to_s]
  end

  #reference JenkinsCheckBuild::Deleted::YES (or NO or UNKNOWN)
  def self.jenkins_job_deleted(ar)
    result_hash(ar)[:deleted.to_s]
  end


end #see https://github.com/RisingOak/jenkins-client/issues/154
#PrismeJob.job_name("JenkinsStartBuild")[0].descendants.leaves.completed(true).first.result
