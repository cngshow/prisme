require 'faraday'
require 'json'
require './lib/ets_common/util/helpers'
include ETSUtilities

NEXUS_CONN = Faraday.new(url: 'http://vadev.mantech.com:8081') do |faraday|
  faraday.request :url_encoded # form-encode POST params
  faraday.use Faraday::Response::Logger, $log
  faraday.headers['Accept'] = 'application/json'
  faraday.adapter :net_http # make requests with Net::HTTP
end

NEXUS_CONN.basic_auth('devtest', 'devtest')

def search_nexus
  url_string = '/nexus/service/local/lucene/search'
  params = {g: 'gov.vha.isaac.gui.rails'}
  params = {p: 'war'}

  url_string = '/nexus/service/local/repositories/snapshots/index_content/gov/vha/isaac/rest/isaac-rest/1.0-SNAPSHOT/'
  # url_string = '/nexus/service/local/repositories/snapshots/index_content/gov/vha/isaac/gui/rails/ets_tooling/1.3-SNAPSHOT'
  # gov/vha/isaac/rest/isaac-rest/1.0-SNAPSHOT/

  response = NEXUS_CONN.get(url_string, params)
  json = JSON.parse(response.body)
  json_to_yaml_file(json, url_to_path_string(url_string))

=begin
  begin
    json = JSON.parse response.body
  rescue JSON::ParserError => ex
    if (response.status.eql?(200))
      return response.body
    end
end
=end

end
# load './lib/nexus.rb'