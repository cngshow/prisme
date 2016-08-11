class TerminologyDbBuilderController < ApplicationController
  before_action :auth_registered
  before_action :ensure_services_configured
  include NexusConcern

  def index
    # retrieve the metadata versions dropdown
    @metadata_versions = load_metadata_drop_down(nexus_params: {g: 'gov.vha.isaac.ochre.modules', a: 'metadata', repositoryId: 'releases'})

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

    job = TerminologyDatabaseBuilder.perform_later(db_name, db_version, db_description, artifact_classifier, classify, ibdf_files, metadata_version)
    PrismeBaseJob.save_user(job_id: job.job_id, user: prisme_user.user_name)

    redirect_to terminology_db_builder_url
  end

  def ajax_check_tag_conflict
    db_name = params['db_name']
    version = params['version']
    tag_conflict = IsaacDBConfigurationCreator.tag_conflict?(name: db_name, version: version)
    render json: {tag_conflict: tag_conflict}
  end

  def ajax_load_build_data
    ret = []

    begin
      row_limit = params[:row_limit]
      data = PrismeJob.job_name('TerminologyDatabaseBuilder').orphan(false).order(completed_at: :desc).limit(row_limit)

      data.each do |jsb|
        row_data = JSON.parse(jsb.to_json)
        row_data['started_at'] = row_data['started_at'].nil? ? nil : DateTime.parse(row_data['started_at']).to_time.to_i
        row_data['completed_at'] = row_data['completed_at'].nil? ?  nil : DateTime.parse(row_data['completed_at']).to_time.to_i
        # "ibdf_files":[{"g":"gov.vha.isaac.terminology.converted","a":"vhat-ibdf","v":"2016.01.07-loader-4.1"},{"g":"gov.vha.isaac.terminology.converted","a":"rf2-ibdf-us-extension","v":"20160301-loader-3.2","r":"","c":"Snapshot"}]
        row_data['ibdf_files'] = TerminologyDatabaseBuilder.ibdf_files(jsb).inject('') { |r, i| r << "#{i['a']}-#{i['v']}<br>" }
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
    prisme_job_has_running_jobs = PrismeJob.has_running_jobs?('TerminologyDatabaseBuilder')
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
