require 'json'
require 'erb'

class TerminologyConverterController < ApplicationController
  before_action :auth_registered
  before_action :ensure_services_configured
  include TerminologyConverterHelper

  def index
    @sources = load_drop_down(nexus_params: {g: 'gov.vha.isaac.terminology.source.*'}).reverse!
  end

  def request_build
    # strip out the individual arguments for term source
    term_source = params[:terminology_source]
    s_hash = TermConvertOption.arg_as_json(term_source)
    s_group_id = s_hash[:g]
    s_artifact_id = s_hash[:a]
    s_version = s_hash[:v]
    converter_options = fetch_converter_options
    # strip out the version argument for converter_version
    converter_version = params[:converter_version]
    cv_hash = TermConvertOption.arg_as_json(converter_version)
    converter_version = cv_hash[:v]

    # initialize the SDOSourceContent based on the selected source
    sdo_source_content = JIsaacLibrary::get_sdo(group_id: s_group_id, artifact: s_artifact_id, version: s_version)

    # pull out the git authentication information
    git_props = Service.get_git_props
    git_url = git_props[PrismeService::GIT_REPOSITORY_URL]
    git_user = git_props[PrismeService::GIT_USER]
    git_pass = git_props[PrismeService::GIT_PWD]

    # nexus url - these variables are in the local binding for the erb - DO NOT REMOVE!
    nexus_props = Service.get_artifactory_props
    nexus_publication_url = nexus_props[PrismeService::NEXUS_PUBLICATION_URL]

    # set the default (empty array) ibdf file dependency and populate it if we have a param passed
    addl_ibdf_dependency = params[:addl_ibdf_dependency]
    addl_ibdf = JIsaacLibrary::ibdf_file_to_j_a()

    if addl_ibdf_dependency
      # strip out the individual arguments for addl_ibdf_dependency
      ibdf_hash = TermConvertOption.arg_as_json(addl_ibdf_dependency)
      ibdf_group_id = ibdf_hash[:g]
      ibdf_artifact_id = ibdf_hash[:a]
      ibdf_version = ibdf_hash[:v]
      ibdf_classifier = params[:ibdf_classifier]
      addl_ibdf = JIsaacLibrary::create_ibdf_sdo_java_array({group_id: ibdf_group_id, artifact: ibdf_artifact_id, version: ibdf_version, classifier: ibdf_classifier}, 'IBDFFile')
    end

    # set the default (empty array) source file dependency and populate it if we have a param passed todo
    addl_source_dependency = params[:addl_source_dependency]
    addl_src = JIsaacLibrary::sdo_source_content_to_j_a()

    if addl_source_dependency
      # strip out the individual arguments for addl_source_dependency
      src_hash = TermConvertOption.arg_as_json(addl_source_dependency)
      src_group_id = src_hash[:g]
      src_artifact_id = src_hash[:a]
      src_version = src_hash[:v]
      src_classifier = src_hash[:c]
      addl_src = JIsaacLibrary::sdo_source_content_to_j_a([src_group_id, src_artifact_id, src_version, src_classifier])
    end

    begin
      converter_option_keys = params.keys.select { |key| key.starts_with?(CONVERTER_OPTION_PREFIX) }
      converter_option_param_hash = converter_option_values(converter_option_keys: converter_option_keys)
      # tag_name is used in erb call below!
      tag_name = IsaacConverter::create_content_converter(sdo_source_content: sdo_source_content,
                                                          converter_version: converter_version,
                                                          additional_source_dependencies_sdo_j_a: addl_src,
                                                          additional_source_dependencies_ibdf_j_a: addl_ibdf,
                                                          converter_option_values: converter_option_param_hash,
                                                          git_url: git_url,
                                                          git_user: git_user,
                                                          git_pass: git_pass)
    rescue => ex
      $log.error("Git call failed!  Message: #{ex.message}")
      $log.error(ex.backtrace.join("\n"))
      raise JIsaacLibrary::GitFailureException.new(ex)
    end

    # these locals are used in erb call below! do not remove!
    development = Rails.env.development?
    git_failure = nil

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
    PrismeBaseJob.save_user(job_id: job.job_id, user: prisme_user.user_name)
    redirect_to action: 'index'
  end

  def ajax_converter_version_change
    converter_options = fetch_converter_options
    json = converter_options.map do |co|
      {display_name: co.display_name, description: co.description, internal_name: co.internal_name, allow_multi_select: co.allow_multi_select?, allow_no_selection: co.allow_no_selection?,
       validation_regex: co.validation_regex, suggested_pick_list_values: co.suggested_pick_list_values.map do |suggested|
         {suggested_value: suggested.value, suggested_description: suggested.description}
       end}
    end
    render partial: 'terminology_converter/ajax_converter_options', locals: {converter_options: json}
  end

  def ajax_term_source_change
    source = params[:term_source]
    locals = {terminology_source: source}
    source_hash = TermConvertOption.arg_as_json(source)

    # get converters based on the selected term source
    source_artifact_id = source_hash[:a]
    isaac_converter = IsaacConverter.get_converter_for_source_artifact(artifactId: source_artifact_id)
    arg = {g: isaac_converter.group_id, a: isaac_converter.artifact_id}
    converters = load_drop_down(nexus_params: arg)
    # converters.reject! { |option| option.version =~ /SNAPSHOT/i } # todo add this back in later
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

  def ajax_ibdf_change
    idbf_selection = params[:ibdf_selection]
    args = idbf_selection.split('|')
    arg = {g: args[0], a: args[1], v: args[2]}
    classifiers = load_ibdf_classifiers(nexus_params: arg)
    render json: {classifiers: classifiers}
  end

  private

  def fetch_converter_options
    converter_version = params[:converter_version]
    args = converter_version.split('|')
    isaac_converter = IsaacConverter::ConverterArtifact.new(group_id: args[0], artifact_id: args[1], version: args[2])
    props = Service.get_artifactory_props
    converter_options = IsaacConverter.get_converter_options(converter: isaac_converter, repository_url: props[PrismeService::NEXUS_REPOSITORY_URL], repository_username: props[PrismeService::NEXUS_USER], repository_password: props[PrismeService::NEXUS_PWD])
    converter_options
  end

  def converter_option_values(converter_option_keys:)
    r_val = {}
    converter_options = fetch_converter_options
    internal_name_to_value_hash = {}
    converter_option_keys.each do |elem|
      key = elem.split(CONVERTER_OPTION_PREFIX).last
      value = elem
      internal_name_to_value_hash[key] = value
    end
    converter_options.each do |pojo_converter_option|
      r_val[pojo_converter_option] = params[internal_name_to_value_hash[pojo_converter_option.internal_name]]
    end
    r_val
  end
end
