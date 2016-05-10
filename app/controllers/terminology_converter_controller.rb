require 'json'
require 'erb'
require './lib/isaac_git_utilities'
include NexusConcern

class TerminologyConverterController < ApplicationController
  before_action :auth_registered
  before_action :ensure_services_configured
  TERM_GROUP_PARAMS = [{g: 'gov.vha.isaac.terminology.source.*'}, {g: 'gov.vha.isaac.terminology.converted'}]

  def index
    TERM_GROUP_PARAMS.each_with_index do |p, idx|
      opts = load_drop_down(idx)
      @sources= opts if idx == 0
      @converts = opts unless idx == 0
    end

  end

  def load_drop_down(idx)
    url_string = '/nexus/service/local/lucene/search'
    group_id_param = TERM_GROUP_PARAMS[idx]
    options = []
    response = get_nexus_connection.get(url_string, group_id_param)
    json = nil

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError => ex
      if (response.status.eql?(200))
        return response.body
      end
    end

    json['data'].each do |artifact|
      options << TermConvertOption.new(artifact['groupId'], artifact['artifactId'], artifact['version'], (idx == 0 ? nil : 'Snapshot')) # todo change this
    end
    options.sort_by!(&:option_key)
    options
  end

  def request_build
    term_source = params[:terminology_source]
    converter_version = params[:converter_version]
    converted_terminology = params[:converted_terminology]

    # strip out the individual arguments for term source
    # s_args = JSON.parse(term_source)
    s_args = term_source.split('|')
    s_group_id = s_args[0]
    s_artifact_id = s_args[1]
    s_version = s_args[2]

    # strip out the individual arguments for converted_terminology
    c_args = converted_terminology.split('|')
    c_group_id = c_args[0]
    c_artifact_id = c_args[1]
    c_version = c_args[2]
    c_classifier = c_args[3]
    sdo_source_content = JIsaacGit::get_sdo(group_id: s_group_id, artifact: s_artifact_id, version: s_version)
    additional_source_dependencies = JIsaacGit::sdo_source_content_to_j_a()

    git_url = $PROPS['ISAAC_GIT.git_url']
    git_user = $PROPS['ISAAC_GIT.git_user']
    git_pass = $PROPS['ISAAC_GIT.git_pass']
    ibdf_a = JIsaacGit::create_ibdf_sdo_java_array({group_id: c_group_id, artifact: c_artifact_id, version: c_version, classifier: c_classifier}, "IBDFFile")
    git_failure = nil
    begin
      tag_name = IsaacConverter::create_content_converter(sdo_source_content: sdo_source_content, converter_version: converter_version, additional_source_dependencies_sdo_j_a: additional_source_dependencies, additional_source_dependencies_ibdf_j_a: ibdf_a, git_url: git_url, git_user: git_user, git_pass: git_pass)
    rescue => ex
      $log.error("Git call failed!  Message: " + ex.message)
      $log.error(ex.backtrace.join("\n"))
      raise JIsaacGit::GitFailureException.new(ex)
    end

    # # look up the replaceable parameters from the YAML file
    # config = YAML.load_file('./config/service/term_convert_definitions.yml')
    # args = config[term_source]
    #
    # # local variables referenced in the erb via binding
    # git_url = args['git_url']
    # root_pom = args['root_pom']
    # artifact_id = args['artifact_id']
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
    JenkinsStartBuild.perform_later("#{JenkinsStartBuild::PRISME_NAME_PREFIX}#{s_artifact_id}_#{t_s}", @job_xml, url, user, password)
    redirect_to action: 'index'
  end

  def get_repo_zip
    # 'http://localhost:8081/nexus/service/local/artifact/maven/content?g=vhat_ibdf&a=converter&v=LATEST&r=vhat_ibdf&c=vhat_ibdf_converters&e=zip'
    url_string = '/nexus/service/local/artifact/maven/content'
    params = {g: 'vhat_ibdf', a: 'converter', v: 'LATEST', r: 'vhat_ibdf', c: 'vhat_ibdf_converters', e: 'zip'}
    File.open('./tmp/vhat_ibdf.zip', 'w') { |f| f.write(get_nexus_connection.get(url_string, params)) }

  end

##################################################################################
# load the source content from nexus using a lucene search based on the group name
##################################################################################
  def load_source_content
    url_string = '/nexus/service/local/lucene/search'
    params = {g: 'gov.vha.isaac.terminology.source.*'}
    response = get_nexus_connection.get(url_string, params)
    json = nil

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError => ex
      if (response.status.eql?(200))
        return response.body
      end
    end

    repo_url = json['repoDetails'].first['repositoryURL']
    # todo what do we do about this gsub!? is this always the case?
    repo_url.gsub!('service/local', 'content')

    # iterate over the results building the sorted TermSource Struct
    hits = json['data']
    data = hits.map { |i| TermSource.new(repoUrl: repo_url, groupId: i['groupId'], artifactId: i['artifactId'], version: i['version']) }.sort_by { |e| [e.get_key] }
    data
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

end


=begin
def process_form2
  term_source = params[:terminology_source]
  source = TermSource.init_from_select_key(term_source) unless term_source.nil?
  base_dir = './tmp/vhat-ibdf/'
  source_version = source.version
  loader_version = 'SNAPSHOT-LOADER-VERSION-KMA'
  erb = 'pom.xml.erb'

  # use 'binding' (method in Kernel) which binds the current block for erb so that the local variables are visible to the pom.xml.erb
  pom_result = ERB.new(File.open("#{base_dir}/#{erb}", 'r') { |file| file.read }).result(binding)

  # write the new pom file out
  File.open("#{base_dir}/pom.xml", 'w') { |f| f.write(pom_result) }

  # delete the pom.xml.erb file
  File.delete("#{base_dir}/#{erb}")

  # move zip to nexus
  # download from nexus to temp
  # unzip in temp


  url_string = source.artifact('pom')
  @pom = get_nexus_connection.get(url_string, {}).body
  @pom = pom_result

end

=end