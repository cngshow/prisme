require 'json'
require 'erb'

class TerminologyConverterController < ApplicationController
  before_action :auth_registered
  before_action :ensure_services_configured
  include TerminologyConverterHelper

  def index
    @sources = load_drop_down(nexus_params: {g: 'gov.vha.isaac.terminology.source.*'}).reverse!
  end

  def ajax_term_source_change
    source = params[:term_source]
    locals = {terminology_source: source}
    source_hash = TermConvertOption.arg_as_json(source)

    # get converters based on the selected term source
    source_artifact_id = source_hash[:a]
    isaac_converter = IsaacConverter::get_converter_for_source_artifact(artifactId: source_artifact_id)
    arg = {g: isaac_converter.group_id, a: isaac_converter.artifact_id}
    converters = load_drop_down(nexus_params: arg).reject { |option| option.version =~ /SNAPSHOT/i }
    locals[:converter_versions] = converters.sort_by! { |obj| obj.version.downcase }.reverse!
    locals[:addl_source_dependency] = []
    locals[:addl_ibdf_dependency] = []

    # check if we need additional dependencies
    dependency = IsaacConverter.get_supported_conversion(artifact_id: source_artifact_id)

    unless (dependency.artifact_dependency.empty?)
      arg = {g: 'gov.vha.isaac.terminology.source.*', a: dependency.artifact_dependency}
      addlSources = load_drop_down(nexus_params: arg)
      addlSources.reject! { |option| option.version =~ /SNAPSHOT/i }
      locals[:addl_source_dependency] = addlSources
    end

    unless (dependency.ibdf_dependency.empty?)
      arg = {g: 'gov.vha.isaac.terminology.converted', a: dependency.ibdf_dependency}
      addlSources = load_drop_down(nexus_params: arg)
      addlSources.reject! { |option| option.version =~ /SNAPSHOT/i }
      locals[:addl_ibdf_dependency] = addlSources
    end

    # render the partial for the user to make their selections
    render partial: 'terminology_converter/term_source_change_content', locals: locals
  end

  def request_build
    term_source = params[:terminology_source]
    converter_version = params[:converter_version]
    converted_terminology = params[:converted_terminology]

    # strip out the individual arguments for term source
    s_hash = TermConvertOption.arg_as_json(term_source)
    s_group_id = s_hash[:g]
    s_artifact_id = s_hash[:a]
    s_version = s_hash[:v]

    # strip out the version argument for converter_version
    cv_hash = TermConvertOption.arg_as_json(converter_version)
    converter_version = cv_hash[:v]

    # initialize the SDOSourceContent based on the selected source
    sdo_source_content = JIsaacGit::get_sdo(group_id: s_group_id, artifact: s_artifact_id, version: s_version)

    # todo what source is used determines if we give it an empty array - need conditional on this!
    additional_source_dependencies = JIsaacGit::sdo_source_content_to_j_a()

    git_props = Service.get_git_props
    git_url = git_props[PrismeService::GIT_REPOSITORY_URL]
    git_user = git_props[PrismeService::GIT_USER]
    git_pass = git_props[PrismeService::GIT_PWD]

    ibdf_a = JIsaacGit::ibdf_file_to_j_a()

    if converted_terminology
      # strip out the individual arguments for converted_terminology
      c_hash = TermConvertOption.arg_as_json(converted_terminology)
      c_group_id = c_hash[:g]
      c_artifact_id = c_hash[:a]
      c_version = c_hash[:v]
      c_classifier = c_hash[:c]
      ibdf_a = JIsaacGit::create_ibdf_sdo_java_array({group_id: c_group_id, artifact: c_artifact_id, version: c_version, classifier: c_classifier}, 'IBDFFile')
    end

    git_failure = nil

    begin
      tag_name = IsaacConverter::create_content_converter(sdo_source_content: sdo_source_content,
                                                          converter_version: converter_version,
                                                          additional_source_dependencies_sdo_j_a: additional_source_dependencies,
                                                          additional_source_dependencies_ibdf_j_a: ibdf_a,
                                                          git_url: git_url,
                                                          git_user: git_user,
                                                          git_pass: git_pass)
    rescue => ex
      $log.error("Git call failed!  Message: #{ex.message}")
      $log.error(ex.backtrace.join("\n"))
      raise JIsaacGit::GitFailureException.new(ex)
    end

    development = Rails.env.development?

    # file to render
    props = Service.get_build_server_props
    j_xml = PrismeService::JENKINS_XML
    url = props[PrismeService::JENKINS_ROOT]
    user = props[PrismeService::JENKINS_USER]
    password = props[PrismeService::JENKINS_PWD]

    # you MUST pass binding in order to have the erb process local variables
    @job_xml = ERB.new(File.open(j_xml, 'r') { |file| file.read }).result(binding)
    t_s = Time.now.strftime('%Y_%m_%dT%H_%M_%S')
    job = JenkinsStartBuild.perform_later("#{JenkinsStartBuild::PRISME_NAME_PREFIX}#{s_artifact_id}_#{t_s}", @job_xml, url, user, password)
    PrismeBaseJob.save_user(job_id: job.job_id, user: current_user.email)
    redirect_to action: 'index'
  end

=begin
  def get_repo_zip
    # 'http://localhost:8081/nexus/service/local/artifact/maven/content?g=vhat_ibdf&a=converter&v=LATEST&r=vhat_ibdf&c=vhat_ibdf_converters&e=zip'
    url_string = '/nexus/service/local/artifact/maven/content'
    params = {g: 'vhat_ibdf', a: 'converter', v: 'LATEST', r: 'vhat_ibdf', c: 'vhat_ibdf_converters', e: 'zip'}
    File.open('./tmp/vhat_ibdf.zip', 'w') { |f| f.write(get_nexus_connection.get(url_string, params)) }
  end
=end

  def ajax_load_build_data
    row_limit = params[:row_limit]
    data = PrismeJob.job_name('JenkinsStartBuild').order(completed_at: :desc).limit(row_limit)
    ret = []

    data.each do |jsb|
      row_data = JSON.parse(jsb.to_json)
      row_data['started_at'] = DateTime.parse(row_data['started_at']).to_time.to_i # todo nil check!!!
      leaf_data = {}
      has_orphan = jsb.descendants.orphan(true).first
      leaf = jsb.descendants.completed(true).orphan(false).leaves.first
      leaf_data['jenkins_check_job_id'] = leaf ? leaf.job_id : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::UNKNOWN)
      leaf_data['jenkins_job_deleted'] = leaf ? JenkinsCheckBuild.jenkins_job_deleted(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_job_name'] = leaf ? JenkinsCheckBuild.jenkins_job_name(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_attempt_number'] = leaf ? JenkinsCheckBuild.attempt_number(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_build_result'] = leaf ? JenkinsCheckBuild.build_result(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['completed_at'] = leaf ? leaf.completed_at.to_i : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)

      if (!row_data['started_at'].nil? && !leaf_data['completed_at'].nil? && leaf_data['completed_at'].is_a?(Numeric))
        leaf_data[:elapsed_time] = ApplicationHelper.convert_seconds_to_time(leaf_data['completed_at'] - row_data['started_at'])
      else
        leaf_data[:elapsed_time] = ''
      end

      row_data['leaf_data'] = leaf_data
      ret << row_data
    end

    render json: ret
  end

  def ajax_check_polling
    prisme_job_has_running_jobs = PrismeJob.has_running_jobs?('JenkinsCheckBuild')
    render json: {poll: prisme_job_has_running_jobs}
  end

end