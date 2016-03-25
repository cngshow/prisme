include NexusConcern

class AppDeployerController < ApplicationController
  def index
    @komet_wars = get_komet_wars
  end

  def deploy_app
    p = params
    url = "http://vadev.mantech.com:8081/nexus/service/local/artifact/maven/content"
    # g a v r c p
    params = {}
    war_info = params['komet_wars'].split('|')
    p[:g] = war_info[0]
    p[:a] = war_info[1]
    p[:v] = war_info[2]
    p[:r] = war_info[3]
    p[:c] = war_info[4]
    p[:p] = war_info[5]

    redirect_to welcome_index_path
  end

  private
  def get_komet_wars
    url_string = '/nexus/service/local/lucene/search'
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
