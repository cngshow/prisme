class TerminologyDbBuilderController < ApplicationController
  before_action :auth_registered
  before_action :ensure_services_configured
  include NexusConcern
  include JenkinsJobConcern

  def index
    # retrieve the metadata versions dropdown
    @metadata_versions = load_metadata_drop_down(nexus_params: {g: 'gov.vha.isaac.ochre.modules', a: 'ochre-metadata', repositoryId: 'releases'})

    # retrieve the list of ibdf options for the multi-select drop down
    @idbf_files = load_ibdf_drop_down(nexus_params: {g: 'gov.vha.isaac.terminology.converted', repositoryId: 'termdata'})
  end

  def request_build
    ibdf_files = params[:ibdf_selections].split(',').map { |f| NexusOption.arg_as_json(f) }
    db_name = params['db_name']
    db_version = params['db_version']
    db_description = params['db_description']
    artifact_classifier = params['artifact_classifier']
    classify = boolean(params['classify'])
    metadata_version = params['metadata_version']

    job = TerminologyDatabaseBuilder.perform_later(db_name, db_version, db_description, artifact_classifier, classify, ibdf_files, metadata_version, {job_tag: PrismeConstants::JobTags::TERMINOLOGY_DB_BUILDER})
    PrismeBaseJob.save_user(job_id: job.job_id, user: prisme_user.user_name)

    redirect_to terminology_db_builder_url
  end

  def ajax_check_tag_conflict
    db_name = params['db_name']
    version = params['version']

    tag_conflict = nil
    begin
      tag_conflict = IsaacDBConfigurationCreator.tag_conflict?(name: db_name, version: version)
    rescue java.lang.Exception  => ex
      $log.error("Error in IsaacDBConfigurationCreator for db_name #{db_name} with version #{version}!! The error is: #{ex}")
      $log.error('Because of this exception I will be returning true (indicating a git tag conflict) and the end user will not be able to proceed.')
      $log.error(ex.backtrace.join("\n"))
      tag_conflict = true
    end
    render json: {tag_conflict: tag_conflict}
  end

  def ajax_load_build_data
    ret = []

    begin
      row_limit = params[:row_limit]
      data = PrismeJob.job_tag(PrismeConstants::JobTags::TERMINOLOGY_DB_BUILDER).is_root(true).orphan(false).order(completed_at: :desc).limit(row_limit)

      data.each do |tdb|
        row_data = JSON.parse(tdb.to_json)
        row_data['ibdf_files'] = TerminologyDatabaseBuilder.ibdf_files(tdb).inject('') { |r, i| r << "#{i['a']}-#{i['v']}<br>" }
        leaf_hash = append_check_build_leaf_data(tdb)
        row_data['leaf_data'] = leaf_hash
        ret << row_data
      end
      render json: ret

    rescue => ex
      $log.error(ex.to_s)
      $log.error(ex.backtrace.join("\n"))
      raise ex
    end
  end

  def ajax_check_polling
    prisme_job_has_running_jobs = PrismeJob.has_running_jobs?(PrismeConstants::JobTags::TERMINOLOGY_DB_BUILDER, true)
    render json: {poll: prisme_job_has_running_jobs}
  end

  private
  def load_metadata_drop_down(nexus_params: nexus_params)
    url_string = '/nexus/service/local/lucene/search'
    options = []
    response = get_nexus_connection.get(url_string, nexus_params)
    json = nil

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError => ex
      if response.status.eql?(200)
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
