include NexusConcern

class AppDeployerController < ApplicationController
  def index
    @komet_wars = get_komet_wars
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
    # Should look sometyhing like this: url = 'http://vadev.mantech.com:8081/nexus/service/local/artifact/maven/content'
    # g a v r c p
    p = {}
    tomcat_id = params[PrismeService::TOMCAT]
    tomcat_ar = Service.find_by(id: tomcat_id)
    komet_war = KometWar.init_from_select_key(params['komet_war'])
    war_name = komet_war.select_value

    war_info = params['komet_war'].split('|')
    p[:g] = war_info[0]
    p[:a] = war_info[1]
    p[:v] = war_info[2]
    p[:r] = war_info[3]
    p[:c] = war_info[4]
    p[:p] = war_info[5]
    url << '?' << p.to_query
    #ActiveRecord Job set to pending
    ArtifactDownloadJob.perform_later(url, war_name, tomcat_ar)
    redirect_to prisme_job_queue_list_path
  end

  private
  def get_komet_wars
    url_string = $PROPS['ENDPOINT.nexus_lucene_search']
    #'/nexus/service/local/lucene/search'
    params = {g: 'gov.vha.isaac.gui.rails', a: 'rails_komet'}
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

    hits = json['data'].first
    ret = []
    group_id = hits['groupId']
    artifact_id = hits['artifactId']
    version = hits['version']
    hits = hits['artifactHits'].first
    repo = hits['repositoryId']
    hits = hits['artifactLinks']

    # only include war files
    hits.keep_if { |h| h['extension'] == 'war' }.each do |h|
      ret << KometWar.new(groupId: group_id, artifactId: artifact_id, version: version, repo: repo, classifier: h['classifier'], package: h['extension'])
    end
    ret
  end
end
