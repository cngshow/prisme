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
      active_record.define_singleton_method(:select_value) do
        self.name
      end
      active_record.define_singleton_method(:select_key) do
        self.id
      end
      active_record.define_singleton_method(:select_option) do
        {key: select_key, value: select_value}
      end
      @tomcat_servers << active_record
    end
    $log.debug(@tomcat_servers.inspect)
  end

  def deploy_app
    # Should look something like this: url = 'http://vadev.mantech.com:8081/nexus/service/local/artifact/maven/content'
    # g a v r c war_cookie_params
    tomcat_id = params[PrismeService::TOMCAT]
    tomcat_ar = Service.find_by(id: tomcat_id)
    application = params['application']
    war_param = application.eql?('KOMET') ? params['komet_war'] : params['isaac_war']
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
    war_cookie_params[:prisme_root] = root_url
    war_cookie_params[:prisme_roles_url] = URI(roles_get_roles_url).to_https if RolesController.ssl_configured?
    war_cookie_params[:prisme_roles_url] = roles_get_roles_url unless RolesController.ssl_configured?
    war_cookie_params[:prisme_roles_ssoi_url] = URI(roles_get_ssoi_roles_url).to_https if RolesController.ssl_configured?
    war_cookie_params[:prisme_roles_ssoi_url] = roles_get_ssoi_roles_url unless RolesController.ssl_configured?
    war_cookie_params[:war_group_id] = war_file.groupId
    war_cookie_params[:war_artifact_id] = war_file.artifactId
    war_cookie_params[:war_version] = war_file.version
    war_cookie_params[:war_repo] = war_file.repo
    war_cookie_params[:war_classifier] = war_file.classifier unless war_file.classifier.empty?
    war_cookie_params[:war_package] = war_file.package

    isaac_db = params['isaac_db']
    unless (isaac_db.nil? || isaac_db.empty?)
      zip_file = NexusArtifactSelectOption.init_from_select_key(isaac_db)
      war_cookie_params[:db_group_id] = zip_file.groupId
      war_cookie_params[:db_artifact_id] = zip_file.artifactId
      war_cookie_params[:db_version] = zip_file.version
      war_cookie_params[:db_repo] = zip_file.repo
      war_cookie_params[:db_classifier] = zip_file.classifier
      war_cookie_params[:db_package] = zip_file.package
    else
      #we komet!!
      war_cookie_params[:isaac_root] =  params['tomcat_isaac_rest']
    end

    job = ArtifactDownloadJob.perform_later(nexus_query_params, war_cookie_params, war_name, tomcat_ar)
    PrismeBaseJob.save_user(job_id: job.job_id, user: prisme_user.user_name)
    session[:select_tabpage] = 1
    redirect_to root_path
  end

  private
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

  def get_isaac_cradle_zips
    url_string = $PROPS['ENDPOINT.nexus_lucene_search']
    params = {g: 'gov.vha.isaac.db', r: 'All', p: 'cradle.zip'}
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
      releases = json['data'].select { |ih| ih['version'] !~ /SNAPSHOT/ }

      if (releases.length > 0)
        releases.each do |artifact|
          g = artifact['groupId']
          a = artifact['artifactId']
          v = artifact['version']
          repo = artifact['latestReleaseRepositoryId']
          c = artifact['artifactHits'].first['artifactLinks'].select { |al| al['extension'].eql?('cradle.zip') }.first['classifier']
          ret << NexusArtifactSelectOption.new(groupId: g, artifactId: a, version: v, repo: repo, classifier: c, package: 'cradle.zip')
        end
      else
        $log.info('no releases found!!')
      end
    else
      $log.info('no ISAAC cradle zips found!!!')
    end
    ret
  end
end
