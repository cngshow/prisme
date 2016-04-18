include NexusConcern

class AppDeployerController < ApplicationController

  before_action :auth_registered

  def index
    @komet_wars = get_nexus_wars(app: 'KOMET')
    @isaac_wars = get_nexus_wars(app: 'ISAAC')

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
    nexus_props = Service.get_artifactory_props
    url = nexus_props[PrismeService::NEXUS_ROOT] + $PROPS['ENDPOINT.nexus_maven_content']
    # Should look something like this: url = 'http://vadev.mantech.com:8081/nexus/service/local/artifact/maven/content'
    # g a v r c p
    p = {}
    tomcat_id = params[PrismeService::TOMCAT]
    tomcat_ar = Service.find_by(id: tomcat_id)
    application = params['application']
    war_param = application.eql?('KOMET') ? params['komet_war'] : params['isaac_war']
    war_file = NexusWar.init_from_select_key(war_param)
    war_name = war_file.select_value

    war_info = war_param.split('|')
    p[:g] = war_info[0]
    p[:a] = war_info[1]
    p[:v] = war_info[2]
    p[:r] = war_info[3]
    p[:c] = war_info[4] unless war_info[4].empty?
    p[:p] = war_info[5]
    url << '?' << p.to_query
    #ActiveRecord Job set to pending
    ArtifactDownloadJob.perform_later(url, war_name, tomcat_ar)
    redirect_to prisme_job_queue_list_path
  end

  private
  def get_nexus_wars(app:)
    url_string = $PROPS['ENDPOINT.nexus_lucene_search']
    params_hash = {'KOMET' => {g: 'gov.vha.isaac.gui.rails', a: 'rails_komet', repositoryId: 'releases', p: 'war'},
                   'ISAAC' => {g: 'gov.vha.isaac.rest', a: 'isaac-rest', repositoryId: 'releases', p: 'war'}}
    params = params_hash[app]
    conn = NexusConcern.get_nexus_connection
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
          ret << NexusWar.new(groupId: g, artifactId: a, version: v, repo: repo, classifier: h['classifier'], package: h['extension'])
        end
      end
    else
      puts 'no war files found!!!'
    end
    ret
  end
end
