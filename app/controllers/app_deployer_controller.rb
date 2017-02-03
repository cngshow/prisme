class AppDeployerController < ApplicationController
  include TomcatConcern
  include NexusConcern

  before_action :auth_registered
  before_action :ensure_services_configured

  def index
    @komet_wars = get_nexus_wars(app: 'KOMET')
    @isaac_wars = get_nexus_wars(app: 'ISAAC')
    @isaac_dbs = get_isaac_cradle_zips
    @tomcat_isaac_rest = []

    tomcat_server_deployments.each do |tsd|
      service_name = tsd.first[:service_name]

      tsd.last.each do |d|
        if (d.first =~ /isaac-rest/i)
          select_key = d.last[:link]
          select_value = "#{service_name}::#{d.first}"
          @tomcat_isaac_rest << {select_key: select_key, select_value: select_value}
        end
      end
    end

    if @komet_wars.nil? || @isaac_wars.nil?
      render :file => 'public/nexus_not_available.html'
      return
    end

    @tomcat_servers = []
    Service.where(service_type: PrismeService::TOMCAT).each do |active_record|
      PrismeUtilities.get_proxy_contexts(tomcat_ar: active_record, application_type: PrismeUtilities::ISAAC_APPLICATION).each do |context|
        hash = {}
        hash[:tomcat_ar] = active_record
        hash[:context] = context
        active_record.define_singleton_method(:select_value) do
          active_record.name
        end
        hash.define_singleton_method(:select_value) do
          active_record.name + '--' + context
        end
        hash.define_singleton_method(:select_key) do
          active_record.id.to_s + '|' + context
        end
        active_record.define_singleton_method(:select_key) do
          active_record.id.to_s
        end
        @tomcat_servers << hash unless context.nil?
      end
    end
    $log.debug(@tomcat_servers.inspect)
  end

  def deploy_app
    # Should look something like this: url = 'http://vadev.mantech.com:8081/nexus/service/local/artifact/maven/content'
    # g a v r c war_cookie_params
    tomcat_id, context = nil, nil
    params.each do |k, v|
      if ((k =~ /^#{PrismeService::TOMCAT}.*app_server$/) && !v.empty?)
        tomcat_id, context = v.split('|')
        break
      end
    end
    tomcat_ar = Service.find_by(id: tomcat_id)
    application_type = params[:application]
    application_name = params[:application_name]
    application_description = params[:application_description]
    war_param = application_type.eql?('KOMET') ? params['komet_war'] : params['isaac_war']
    war_file = NexusArtifactSelectOption.init_from_select_key(war_param)
    war_name = war_file.select_value
    war_cookie_params = {}
    nexus_query_params = {}

    nexus_query_params[:g] = war_file.groupId
    nexus_query_params[:a] = war_file.artifactId
    nexus_query_params[:v] = war_file.version
    nexus_query_params[:r] = war_file.repo
    nexus_query_params[:c] = war_file.classifier unless war_file.classifier.empty?
    nexus_query_params[:p] = war_file.package
    war_cookie_params[:prisme_root] = non_proxy_url(path_string: root_path)
    war_cookie_params[:prisme_roles_user_url] = non_proxy_url(path_string: roles_get_user_roles_path) << '.json'
    war_cookie_params[:prisme_roles_ssoi_url] = non_proxy_url(path_string: roles_get_ssoi_roles_path) << '.json'
    war_cookie_params[:prisme_roles_by_token_url] = non_proxy_url(path_string: roles_get_roles_by_token_path) << '.json'
    war_cookie_params[:prisme_config_url] = non_proxy_url(path_string: utilities_prisme_config_path) << '.json'
    war_cookie_params[:prisme_all_roles_url] = non_proxy_url(path_string: roles_get_all_roles_path) << '.json'
    security_token = CipherSupport.instance.generate_security_token
    war_cookie_params[:prisme_all_service_props_url] = non_proxy_url(path_string: all_services_as_json_path) << '.json' << '?security_token=' + security_token
    war_cookie_params[:prisme_notify_url] = non_proxy_url(path_string: log_event_path) << '.json' << '?security_token=' + security_token
    war_cookie_params[:war_group_id] = war_file.groupId
    war_cookie_params[:war_artifact_id] = war_file.artifactId
    war_cookie_params[:war_uuid] = SecureRandom.uuid
    name_war(war_cookie_params[:war_uuid],application_name, application_description)
    war_cookie_params[:war_version] = war_file.version
    war_cookie_params[:war_repo] = war_file.repo
    war_cookie_params[:war_classifier] = war_file.classifier unless war_file.classifier.empty?
    war_cookie_params[:war_package] = war_file.package

    # check if isaac_db is passed to determine if this is a komet or an isaac deployment
    isaac_db = params['isaac_db']

    if isaac_db.nil? || isaac_db.empty?
      #we are komet!!
      war_cookie_params[:isaac_root] = params['tomcat_isaac_rest']
    else
      zip_file = NexusArtifactSelectOption.init_from_select_key(isaac_db)
      war_cookie_params[:db_group_id] = zip_file.groupId
      war_cookie_params[:db_artifact_id] = zip_file.artifactId
      war_cookie_params[:db_version] = zip_file.version
      war_cookie_params[:db_repo] = zip_file.repo
      war_cookie_params[:db_classifier] = zip_file.classifier
      war_cookie_params[:db_package] = zip_file.package
    end

    job = AppDeploymentJob.perform_later(nexus_query_params, war_cookie_params, war_name, tomcat_ar, context, {job_tag: PrismeConstants::JobTags::APP_DEPLOYER})
    PrismeBaseJob.update_json_data(job_id: job.job_id, json_data: {message: "Deploying #{war_name}...Please wait"})
    PrismeBaseJob.save_user(job_id: job.job_id, user: prisme_user.user_name)
    redirect_to app_deployer_path
  end

  def reload_deployments
    ret = []

    begin
      row_limit = params[:row_limit] ||= 15
      data = PrismeJob.job_tag(PrismeConstants::JobTags::APP_DEPLOYER).is_root(true).orphan(false).order(completed_at: :desc).limit(row_limit)

      data.each do |app_dep|
        row_data = app_dep.as_json
        row_data['started_at'] = row_data['started_at'].to_i
        row_data['leaf_data'] = leaf_data(app_dep)
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
    prisme_job_has_running_jobs = PrismeJob.has_running_jobs?(PrismeConstants::JobTags::APP_DEPLOYER, true)
    render json: {poll: prisme_job_has_running_jobs}
  end

  private

  def name_war(uuid, name, description)
    uuid_active_record = UuidProp.uuid(uuid: uuid)
    begin
      uuid_active_record.save_json_hash!(UuidProp::Keys::NAME => name, UuidProp::Keys::DESCRIPTION => description, UuidProp::Keys::LAST_EDITED_BY => prisme_user.user_name)
    rescue => ex
      $log.warn("The name war failed for uuid #{uuid}")
      $log.warn("The name would have been #{name}")
      $log.warn("The deploy will continue, the user will have to name from the home screen...")
      $log.warn(ex.message)
      $log.warn(ex.backtrace.join("\n"))
    end
  end

  def leaf_data(row)
    ret_data = {}

    if row.status != PrismeJobConstants::Status::STATUS_HASH[:COMPLETED]
      ar = row
    else
      leaf = row.descendants.leaves.first
      ar = leaf
      ret_data = leaf.as_json
    end

    ret_data['orphaned_leaf'] = ar['status'] == PrismeJobConstants::Status::STATUS_HASH[:ORPHANED]
    ret_data['running'] = false
    ret_data['tooltip'] = ''

    case ar['status']
      when PrismeJobConstants::Status::STATUS_HASH[:FAILED]
        ret_data['running_msg'] = 'Job Execution Failed. See the tooltip for the error message.'
        ret_data['tooltip'] = ar['last_error']
      when PrismeJobConstants::Status::STATUS_HASH[:ORPHANED]
        ret_data['running_msg'] = 'Job was orphaned. The application deployment failed.'
      else
        ret_data['running'] = !ret_data['job_name'].eql?(DeployWarJob.name) || ar['completed_at'].nil?

        if ar['json_data'].nil?
          ret_data['running_msg'] = ar['result']
        else
          ret_data['running_msg'] = JSON.parse(ar['json_data'])['message']
          ret_data['tooltip'] = JSON.parse(ar['json_data'])['tooltip'] ||= ''
        end
    end

    if row['started_at'] && !ret_data['orphaned_leaf']
      ret_data['completed_at'] = ret_data['completed_at'] ||= Time.now.to_i
      ret_data['elapsed_time'] = ApplicationHelper.convert_seconds_to_time(ret_data['completed_at'] - row['started_at'].to_i)
    else
      ret_data['elapsed_time'] = ''
    end

    ret_data
  end

  def get_nexus_wars(app:)
    url_string = $PROPS['ENDPOINT.nexus_lucene_search']
    params_hash = {'KOMET' => {g: 'gov.vha.isaac.gui.rails', a: 'rails_komet', repositoryId: 'releases', p: 'war'},
                   'ISAAC' => {g: 'gov.vha.isaac.rest', a: 'isaac-rest', repositoryId: 'releases', p: 'war'}}
    params = params_hash[app]
    conn = get_nexus_connection
    response = conn.get(url_string, params)
    json = nil

    begin
      json = JSON.parse response.body
    rescue JSON::ParserError => ex
      if (response.status.eql?(200))
        return response.body
      end
    end

    return nil if json.nil?
    ret = []

    if (json['totalCount'].to_i > 0)
      json['data'].each do |artifact|
        g = artifact['groupId']
        a = artifact['artifactId']
        v = artifact['version']
        lr = artifact['latestRelease'] # use this for styling??
        hits = artifact['artifactHits'].first
        repo = hits['repositoryId']
        links = hits['artifactLinks']

        # only include war files
        links.keep_if { |h| h['extension'] == 'war' }.each do |h|
          ret << NexusArtifactSelectOption.new(groupId: g, artifactId: a, version: v, repo: repo, classifier: h['classifier'], package: h['extension'])
        end
      end
    else
      $log.info('no war files found!!!')
    end
    ret
  end

end
