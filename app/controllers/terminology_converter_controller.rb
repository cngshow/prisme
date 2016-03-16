require 'json'

class TerminologyConverterController < ApplicationController
  def setup
    @options = load_source_content
    render 'terminology_converter/wizard'
  end

  def process_form
  end

  TermSource = Struct.new(:repoUrl, :groupId, :artifactId, :version) do
    def get_full_path
      "#{repoUrl}/#{groupId.gsub('.', '/')}/#{artifactId}/#{version}/"
    end

    def artifact(ext)
      "#{get_full_path}#{artifactId}-#{version}.#{ext}"
    end

    def get_key
      "#{groupId}-#{artifactId}-#{version}"
    end

    def select_option
      {key: get_key, value: "#{artifactId} version #{version}"}
    end
  end

=begin
  private

  # setup the nexus connection
  # todo move this to an initializer?
  def get_nexus_connection
    nexus_conn = Faraday.new(url: $PROPS['ENDPOINT.nexus_root']) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.use Faraday::Response::Logger, $log
      faraday.headers['Accept'] = 'application/json'
      faraday.adapter :net_http # make requests with Net::HTTP
    end

    nexus_conn.basic_auth('devtest', 'devtest')
    nexus_conn
 end
=end

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
    hits.map { |i| Struct::TermSource.new(repo_url, i['groupId'], i['artifactId'], i['version']) }.sort_by { |e| [e.get_key] }
  end
end
