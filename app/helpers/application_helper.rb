require 'faraday'

module ApplicationHelper
  # http://localhost:8180/rest/1/taxonomy/version
  def get_nexus_connection
    nexus_conn = Faraday.new(url: $PROPS['ENDPOINT.nexus_root']) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.use Faraday::Response::Logger, $log
      faraday.headers['Accept'] = 'application/json'
      faraday.adapter :net_http # make requests with Net::HTTP
      faraday.basic_auth($PROPS['ENDPOINT.nexus_user'], $PROPS['ENDPOINT.nexus_pwd'])
    end
    nexus_conn
  end

end
