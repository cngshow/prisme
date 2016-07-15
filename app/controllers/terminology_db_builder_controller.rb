# require 'json'
# require 'erb'## todo do we need this?

class TerminologyDbBuilderController < ApplicationController
  before_action :auth_registered
  before_action :ensure_services_configured
  include NexusConcern

  def index
    @metadata_versions = load_metadata_drop_down(nexus_params: {g: 'gov.vha.isaac.ochre.modules', a: 'metadata', repositoryId: 'releases'})

    # retrieve the list of ibdf options for the multi-select drop down
    @idbf_files = load_ibdf_drop_down(nexus_params: {g: 'gov.vha.isaac.terminology.converted', repositoryId: 'termdata'})
  end

=begin
  def ajax_term_source_change
    source = params[:term_source]
    locals = {terminology_source: source}
    source_hash = TermConvertOption.arg_as_json(source)

    # get converters based on the selected term source
    source_artifact_id = source_hash[:a]
    isaac_converter = IsaacConverter.get_converter_for_source_artifact(artifactId: source_artifact_id)
    #isaac_converter_new_for_greg = IsaacConverter::ConverterArtifact.new(group_id: "gov.vha.isaac.terminology.converters", artifact_id: "rf2-mojo", version: "3.3-SNAPSHOT")
    #props = Service.get_artifactory_props
    #converter_options = IsaacConverter.get_converter_options(converter: isaac_converter_new_for_greg, repository_url: props[PrismeService::NEXUS_REPOSITORY_URL], repository_username: props[PrismeService::NEXUS_USER], repository_password: props[PrismeService::NEXUS_PWD])
    #converter_options.map do |co| [co.display_name, co.description, co.internal_name, co.allow_multi_select?, co.allow_no_selection?, co.suggested_pick_list_values]end
    #converter_options.first.suggested_pick_list_values.map do |suggested|[suggested.value, suggested.description] end
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
=end

  def request_build

    ibdf_files = params[:ibdf_selections].split(',').map {|f| NexusOption.arg_as_json(f)}
    db_name = params['db_name']
    db_version = params['db_version']
    db_description = params['db_description']
    artifact_classifier = params['artifact_classifier']
    classify = boolean(params['classify'])
    metadata_version = params['metadata_version']

    job = TerminologyDatabaseBuilder.perform_later(db_name, db_version, db_description, artifact_classifier, classify, ibdf_files, metadata_version)
    PrismeBaseJob.save_user(job_id: job.job_id, user: current_user.email)

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
    prisme_job_has_running_jobs = PrismeJob.has_running_jobs?('JenkinsCheckBuild??todo')#todo
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
=begin
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
=end

  def load_metadata_drop_down(nexus_params: nexus_params)
    url_string = '/nexus/service/local/lucene/search'
    options = []
    response = get_nexus_connection.get(url_string, nexus_params)
    json = nil

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError => ex
      if (response.status.eql?(200))
        return response.body
      end
    end

    if (json && json.has_key?('data'))
      json['data'].each do |d|
        options << NexusOption.new({g: d['groupId'], a: d['artifactId'], v: d['version']})
      end

      options.sort_by!(&:option_key).reverse! #the reverse will make the most recent versions on top
    else
      $log.debug("EMPTY nexus repository search for #{url_string}&#{nexus_params}")
    end

      options
  end

  def load_ibdf_drop_down(nexus_params: nexus_params)
    url_string = '/nexus/service/local/lucene/search'
    options = []
    response = get_nexus_connection.get(url_string, nexus_params)
    json = nil

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError => ex
      if (response.status.eql?(200))
        return response.body
      end
    end

    if (json && json.has_key?('data'))
      options = []
      json['data'].each do |data|
        opt = {g: data['groupId'], a: data['artifactId'], v: data['version']}
        hits = data['artifactHits'].first['artifactLinks'].select { |d| d['extension'].eql?('ibdf.zip') }
        hits.each do |hit|
          option = opt.clone
          option[:c] = hit['classifier'] ||= ''
          options << NexusOption.new(option)
        end
      end

      options.sort_by!(&:option_key).reverse!
    else
      $log.debug("EMPTY nexus repository search for #{url_string}&#{nexus_params}")
    end

      options
  end

end
