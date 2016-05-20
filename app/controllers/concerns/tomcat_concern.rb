require 'faraday'
require 'uri'

module TomcatConcern
  VALID_ACTIONS = [:start, :stop, :undeploy]

  # change_state(url: "http://localhost:8080/",username: "devtest",pwd: "devtest", context: "rails_komet_b", path: 'start')
  def change_state(tomcat_service_id:, context:, action:)
    unless (VALID_ACTIONS.include?(action.to_sym))
      $log.error("Invalid action, #{action}, passed into change_state method. Valid actions are: #{VALID_ACTIONS.to_s}.")
      raise StandardError.new("Invalid action, #{action}, passed into change_state method. Valid actions are: #{VALID_ACTIONS.to_s}.")
    end

    begin
      context = '/' + context unless context[0].eql?('/')
      conn = get_connection(service_or_id: tomcat_service_id)

      # this should not get hit, however, raise an exception if conn is nil
      raise "Tomcat Connection Error. Unable to get a Tomcat Connection for #{tomcat_service_id.to_s}" if conn.nil?

      # make the rest call to change the state of the tomcat deployment based on the action (start, stop, undeploy) and the context (rails_komet, etc.)
      response = conn.get("/manager/text/#{action}", {path: context})
    rescue Faraday::ConnectionFailed => ex
      $log.warn("Tomcat is unreachable! #{ex.message}")
      return {failed: ex.message}
    rescue => ex
      $log.warn("Unexpected Exception: #{ex.message}")
      return {failed: ex.message}
    end
    response.body
  end

  private
  def get_connection(service_or_id:)
    conn = nil

    if (service_or_id.is_a? Service)
      tomcat_service = service_or_id
    else
      tomcat_service = Service.find_by!(id: service_or_id)
    end

    # verify that we have a tomcat service
    if (tomcat_service.service_type.eql?(PrismeService::TOMCAT))
      service_props = tomcat_service.properties_hash
      url = service_props[PrismeService::CARGO_REMOTE_URL]
      username = service_props[PrismeService::CARGO_REMOTE_USERNAME]
      pwd = service_props[PrismeService::CARGO_REMOTE_PASSWORD]

      conn = Faraday.new(url: url) do |faraday|
        faraday.request :url_encoded # form-encode POST params
        faraday.use Faraday::Response::Logger, $log
        faraday.adapter :net_http # make requests with Net::HTTP
        faraday.basic_auth(username, pwd)
      end
    else
      raise StandardError.new('Invalid tomcat service passed to TomcatConcern.get_deployments!')
    end
    conn
  end

  def get_deployments(tomcat_service:)
    conn = get_connection(service_or_id: tomcat_service)

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
        vars = line.strip.split(':')
        war = vars[3] #war is 'isaac_rest' or rails_komet_b or similar with version
        # filter to only display isaac and rails war files
        next unless war =~ /^(isaac|rails_k).*/
        ret_hash[war] = {}
        ret_hash[war][:context] = vars[0]
        ret_hash[war][:state] = vars[1]
        ret_hash[war][:session_count] = vars[2]
        ret_hash[war][:version] = get_version(war: war, context: vars[0], tomcat_service: tomcat_service)
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

  def get_version(war:, context:, tomcat_service:)
    conn = get_connection(service_or_id: tomcat_service)
    path = ''
    version = 'UNKNOWN'
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
      json['version'] = 'INVALID_JSON'
      json['restVersion'] = 'INVALID_JSON'
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
      data_hash = get_deployments(tomcat_service: tomcat)

      # build the url to the tomcat server
      url = URI.parse(tomcat.properties_hash[PrismeService::CARGO_REMOTE_URL])
      scheme = url.scheme
      host = url.host
      port = url.port

      # build the link for each deployment
      if data_hash.has_key?(:failed)
        tomcat_deployments[{url: url, service_name: tomcat.name}] = {}
      else
        data_hash.each do |d|
          context = d.last[:context]
          link = "#{scheme}://#{host}:#{port}#{context}"
          d.last[:link] = link
        end

        tomcat_deployments[{url: url, service_name: tomcat.name, service_id: tomcat.id}] = data_hash
      end
    end
    tomcat_deployments
  end
end
