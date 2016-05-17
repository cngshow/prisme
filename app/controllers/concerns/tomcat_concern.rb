require 'faraday'
require 'uri'

module TomcatConcern

# change_state(url: "http://localhost:8080/",username: "devtest",pwd: "devtest", context: "rails_komet_b", path: 'start')
  def change_state(url:, username:, pwd:, context:, path:)
    context = '/' + context unless context[0].eql?('/')

    conn = get_connection(url: url, username: username, pwd: pwd)
    begin
      response = conn.get("/manager/text/#{path}", {path: path})
    rescue Faraday::ConnectionFailed => ex
      $log.warn("Tomcat is unreachable! #{ex.message}")
      return {failed: ex.message}
    end
    response.body
  end

  def get_deployments(url:, username:, pwd:)

    conn = get_connection(url: url, username: username, pwd: pwd)
    # get the list of deployed applications
    response = nil

    begin
      response = conn.get('/manager/text/list', {})
    rescue Faraday::ConnectionFailed => ex
      return {failed: ex.message}
    end

    if (response.status.eql?(200))
      data = response.body

      # parse the response body
      data = data.split("\n") # get each line
      data.shift # remove the OK line
      ret_hash = {}


      data.each do |line|
        vars = line.split(':')
        war = vars[3] #war is 'isaac_rest' or rails_komet_b or similiar with version
        # filter to only display isaac and rails war files
        next unless war =~ /^(isaac|rails_k).*/
        ret_hash[war] = {}
        ret_hash[war][:context] = vars[0]
        ret_hash[war][:state] = vars[1]
        ret_hash[war][:session_count] = vars[2]
        ret_hash[war][:version] = get_version(war: war, context: vars[0], url: url, username: username, pwd: pwd)
      end
      $log.debug("Returning #{ret_hash}")
      #      {"ROOT"=>{:context=>"/", :state=>"running", :session_count=>"0"}, "isaac-rest"=>{:context=>"/isaac-rest", :state=>"running
      # ", :session_count=>"0"}, "rails_komet_a"=>{:context=>"/rails_komet_a", :state=>"running", :session_count=>"0"}, "/usr/share/tomcat7-admin/host-manager"=>{:context=>"/host-manager", :state=>"running", :session_count=>"0"}, "rail
      # s_prisme"=>{:context=>"/rails_prisme", :state=>"running", :session_count=>"0"}, "/usr/share/tomcat7-admin/manager"=>{:context=>"/manager", :state=>"running", :session_count=>"0"}}
      return ret_hash
    else
      return {failed: response.body}
    end
  end

  def get_version(war:, context:, url:, username:, pwd:)
    base_url = URI(url).base_url
    conn = get_connection(url: base_url, username: username, pwd: pwd)
    path = ''
    version = "UNKNOWN"
    response = nil
    if (war =~ /^isaac/)
      path = '/rest/1/system/systemInfo'
    else
      #komet via previous filtering
      path = '/komet_dashboard/version'
    end
    begin
      path = context + path
      response = conn.get(path)
    rescue Faraday::ConnectionFailed => ex
      $log.warn("{path} is unreachable! #{ex.message}")
      return version
    end
    body = response.body
    json = {}
    begin
      json = JSON.parse body
    rescue => ex
      $log.warn("Invalid JSON from " + base_url + path)
      json['version'] = "INVALID_JSON"
      json['restVersion'] = "INVALID_JSON"
    end
    if(war =~ /^isaac/)
      version = json['restVersion'].to_s
      version = 'UNKNOWN' if version.empty? #assume a local run
    else
      version = json['version'].to_s
    end
    version
  end

  def tomcat_server_deployments
    # retrieve tomcat services
    tomcats = Service.get_application_servers
    tomcat_deployments = {}

    # iterate and make faraday call to get the text/list
    tomcats.each do |tomcat|
      # get the properties hash for the tomcat service
      service_props = tomcat.properties_hash
      url = service_props[PrismeService::CARGO_REMOTE_URL]
      username = service_props[PrismeService::CARGO_REMOTE_USERNAME]
      password = service_props[PrismeService::CARGO_REMOTE_PASSWORD]
      data_hash = get_deployments(url: url, username: username, pwd: password)

      # build the url to the tomcat server
      uri = URI.parse(url)
      scheme = uri.scheme
      host = uri.host
      port = uri.port

      # build the link for each deployment
      if data_hash.has_key?(:failed)
        tomcat_deployments[{url: url, service_name: tomcat.name}] = {}
      else
        data_hash.each do |d|
          context = d.last[:context]
          link = "#{scheme}://#{host}:#{port}#{context}"
          d.last[:link] = link
        end

        tomcat_deployments[{url: url, service_name: tomcat.name}] = data_hash
      end
    end
    tomcat_deployments
  end

  private

  def get_connection(url:, username:, pwd:)
    conn = Faraday.new(url: url) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.use Faraday::Response::Logger, $log
      faraday.adapter :net_http # make requests with Net::HTTP
      faraday.basic_auth(username, pwd)
    end
    conn
  end

end
