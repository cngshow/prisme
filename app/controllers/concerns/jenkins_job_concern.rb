module JenkinsJobConcern
  # this method takes an array of database rows for a given job run and appends the JenkinsCheckBuild data to it
  def append_check_build_leaf_data(row)
    row_data = {}
    started_at = row['started_at']
    row_data['started_at'] = started_at.nil? ? '' : started_at.to_i

    leaf_data = {}
    has_orphan = row.descendants.orphan(true).first
    leaf = row.descendants.completed(true).orphan(false).leaves.first

    if !leaf.nil? && leaf.job_name.eql?(JenkinsCheckBuild.class_name)
      leaf_data['jenkins_check_job_id'] = leaf ? leaf.job_id : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::UNKNOWN)
      leaf_data['jenkins_job_deleted'] = leaf ? JenkinsCheckBuild.jenkins_job_deleted(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_job_name'] = leaf ? JenkinsCheckBuild.jenkins_job_name(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_attempt_number'] = leaf ? JenkinsCheckBuild.attempt_number(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_build_result'] = leaf ? JenkinsCheckBuild.build_result(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['completed_at'] = leaf ? leaf.completed_at.to_i : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)

      if !row_data['started_at'].nil? && !leaf_data['completed_at'].nil? && leaf_data['completed_at'].is_a?(Numeric)
        leaf_data[:elapsed_time] = ApplicationHelper.convert_seconds_to_time(leaf_data['completed_at'] - row_data['started_at'])
      else
        leaf_data[:elapsed_time] = ''
      end
    else
      # no leaf yet so return defaults
      leaf_data['jenkins_check_job_id'] = has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::UNKNOWN
      leaf_data['jenkins_job_deleted'] = has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS
      leaf_data['jenkins_job_name'] = has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS
      leaf_data['jenkins_attempt_number'] = has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS
      leaf_data['jenkins_build_result'] = has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS
      leaf_data['completed_at'] = has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS
      leaf_data[:elapsed_time] = ''
    end
    row_data['leaf_data'] = leaf_data
  end
end
