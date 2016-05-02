require 'json'
require 'erb'
# include ApplicationHelper
include NexusConcern

class TerminologyConverterController < ApplicationController
  # skip_after_action :verify_authorized, :wizard
  before_action :auth_registered
  before_action :ensure_services_configured

  def wizard
    @options = []
    @options << {value: 'https://github.com/VA-CTT/ISAAC-term-convert-rf2.git', key: 'ISAAC-term-convert-rf2'}
    @options << {value: 'https://github.com/VA-CTT/ISAAC-term-convert-vhat.git', key: 'ISAAC-term-convert-vhat'}
    @options << {value: 'https://github.com/VA-CTT/ISAAC-term-convert-loinc.git', key: 'ISAAC-term-convert-loinc'}

    # @options = load_source_content
  end

  def setup_last
    @options = load_source_content
  end

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

  def process_form
    term_source = params[:terminology_source]

    # local variables referenced in the erb via binding
    git_url = term_source
    development = Rails.env.development?

    # file to render
    props = Service.get_build_server_props
    j_xml = PrismeService::JENKINS_XML
    url = props[PrismeService::JENKINS_ROOT]
    user = props[PrismeService::JENKINS_USER]
    password = props[PrismeService::JENKINS_PWD]
    # you MUST pass binding in order to have the erb process local variables
    @job_xml = ERB.new(File.open(j_xml, 'r') { |file| file.read }).result(binding)
    wizard
    name = @options.select do |h|
      git_url.eql?(h[:value])
    end.first[:key]
    t_s = Time.now.strftime('%Y_%m_%dT%H_%M_%S')
    JenkinsStartBuild.perform_later(JenkinsStartBuild::PRISME_NAME_PREFIX + name + "_#{t_s}", @job_xml, url, user, password)
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
    data = PrismeJob.job_name('JenkinsStartBuild').order(completed_at: :desc)
    ret = []

    data.each do |jsb|
      row_data = JSON.parse(jsb.to_json)
      leaf_data = {}
      has_orphan = jsb.descendants.orphan(true).first

      leaf = jsb.descendants.completed(true).orphan(false).leaves.first
      leaf_data['jenkins_check_job_id'] = leaf ? leaf.job_id : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::UNKNOWN)
      leaf_data['jenkins_job_deleted'] = leaf ? JenkinsCheckBuild.jenkins_job_deleted(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_job_name'] = leaf ? JenkinsCheckBuild.jenkins_job_name(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_attempt_number'] = leaf ? JenkinsCheckBuild.attempt_number(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['jenkins_build_result'] = leaf ? JenkinsCheckBuild.build_result(leaf) : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      leaf_data['completed_at'] = leaf ? leaf.completed_at : (has_orphan ? JenkinsCheckBuild::BuildResult::SERVER_ERROR : JenkinsCheckBuild::BuildResult::IN_PROCESS)
      row_data['leaf_data'] = leaf_data
      ret << row_data
    end

    render json: ret
  end

  def ajax_check_polling
    render json: {poll: PrismeJob.has_running_jobs?('JenkinsCheckBuild')}
  end
end
