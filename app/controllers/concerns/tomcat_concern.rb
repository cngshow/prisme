require 'faraday'
require 'uri'

#The TomcatConcern must catch all Faraday::ClientError (all Faraday errors are subclasses of this) and not let them propagate to the
#general handler.  The general handler will assume it is tied to Nexus.
module TomcatConcern
  VALID_ACTIONS = [:start, :stop, :undeploy]
  ISAAC_SYSTEM_INFO_PATH = '/rest/1/system/systemInfo'
  KOMET_VERSION_PATH = '/komet_dashboard/version?include_isaac=true'
  RUNNING_STATE = 'running'
  STATE_CHANGE_SUCCEDED = 'OK'

  # change_state(url: "http://localhost:8080/",username: "devtest",pwd: "devtest", context: "rails_komet_b", path: 'start')
  def change_state(tomcat_service_id:, context:, action:)
    $log.always(prisme_user.user_name + " has issued to '#{Service.find(tomcat_service_id).description}' against context '#{context}' the action '#{action}'")
    unless VALID_ACTIONS.include?(action.to_sym)
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
    rescue Faraday::ClientError => ex
      $log.warn("Tomcat is unreachable! #{ex.message}")
      return {failed: ex.message}
    rescue => ex
      [$log, $alog].each { |l| l.warn("Unexpected Exception: #{ex.message}")}
      @change_state_succeded = false
      return {failed: ex.message}
    end
    $alog.always(prisme_user.user_name + " has a result of: #{response.body}")
    @change_state_succeded = response.body.strip.start_with?(STATE_CHANGE_SUCCEDED)
    response.body
  end

  private
  def get_connection(service_or_id:)
    conn = nil

    if service_or_id.is_a? Service
      tomcat_service = service_or_id
    else
      tomcat_service = Service.find_by!(id: service_or_id)
    end

    # verify that we have a tomcat service
    if tomcat_service.service_type.eql?(PrismeService::TOMCAT)
      service_props = tomcat_service.properties_hash
      url = service_props[PrismeService::CARGO_REMOTE_URL]
      username = service_props[PrismeService::CARGO_REMOTE_USERNAME]
      pwd = service_props[PrismeService::CARGO_REMOTE_PASSWORD]

      conn = Faraday.new(url: url) do |faraday|
        faraday.options.open_timeout = 30
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
    rescue Faraday::ClientError => ex
      $log.error("Could not get the listing of applications from Tomcat: #{ex}")
      $log.error(ex.backtrace.join("\n"))
      return {failed: ex.message}
    end

    if response.status.eql?(200)
      data = response.body
      $log.trace('manager/text list is:')
      $log.trace("#{data}")

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
        version_hash = get_version_hash(war: war, context: vars[0], tomcat_service: tomcat_service, state: ret_hash[war][:state])
        ret_hash[war][:version] = version_hash[:version]
        ret_hash[war][:isaac] = version_hash[:isaac] if version_hash[:isaac]
        ret_hash[war][:komets_isaac_version] = version_hash[:isaac][:isaac_version] if (version_hash[:isaac] && version_hash[:isaac][:isaac_version])
        ret_hash[war][:war_id] = version_hash[:war_id]
      end

      if ret_hash.empty?
        ret_hash = {available: true}
      end
      #      {"ROOT"=>{:context=>"/", :state=>"running", :session_count=>"0"}, "isaac-rest"=>{:context=>"/isaac-rest", :state=>"running
      # ", :session_count=>"0"}, "rails_komet_a"=>{:context=>"/rails_komet_a", :state=>"running", :session_count=>"0"}, "/usr/share/tomcat7-admin/host-manager"=>{:context=>"/host-manager", :state=>"running", :session_count=>"0"}, "rail
      # s_prisme"=>{:context=>"/rails_prisme", :state=>"running", :session_count=>"0"}, "/usr/share/tomcat7-admin/manager"=>{:context=>"/manager", :state=>"running", :session_count=>"0"}}
      return ret_hash
    else
      return {failed: response.body}
    end
  end

  def get_version_hash(war:, context:, tomcat_service:, state:)
    conn = get_connection(service_or_id: tomcat_service)
    path = ''
    response = nil
    version_hash = {version: 'UNKNOWN'}
    if war =~ /^isaac/
      path = ISAAC_SYSTEM_INFO_PATH
    else
      #komet via previous filtering
      path = KOMET_VERSION_PATH
    end
    begin
      path = context + path
      response = conn.get(path)
    rescue Faraday::ClientError => ex
      $log.warn("#{path} is unreachable! #{ex.message}")
      return version_hash
    end
    body = response.body
    json = {}
    begin
      json = JSON.parse body
    rescue => ex
      $log.warn("JSON was not parsed! #{ex}")
      json['version'] = 'INVALID_JSON'
      json['restVersion'] = 'INVALID_JSON'
    end
    version_hash[:isaac] = {}
    if war =~ /^isaac/
      version_hash[:version] = json['apiImplementationVersion'].to_s unless json['apiImplementationVersion'].to_s.empty?
      version_hash[:war_id] = json[UuidProp::ISAAC_WAR_ID].to_s unless json[UuidProp::ISAAC_WAR_ID].to_s.empty?
      version_hash[:isaac][:database] = json['isaacDbDependency']
      version_hash[:isaac][:database_dependencies] = json['dbDependencies']
      UuidProp.uuid(uuid: version_hash[:war_id], state: state)
    else
      version_hash[:version] = json['version'].to_s
      version_hash[:war_id] = json[UuidProp::KOMET_WAR_ID].to_s unless json[UuidProp::KOMET_WAR_ID].to_s.empty?
      version_hash[:isaac][:isaac_version] = json['isaac_version']['apiImplementationVersion'].to_s rescue "unknown isaac version"
      version_hash[:isaac][:war_id] = json['isaac_version'][UuidProp::ISAAC_WAR_ID].to_s rescue nil
      #record my dependency
      UuidProp.uuid(uuid: version_hash[:war_id], dependent_uuid: version_hash[:isaac][:war_id], state: state)
      version_hash[:isaac][:database] = json['isaac_version']['isaacDbDependency'] rescue nil
      version_hash[:isaac][:database_dependencies] = json['isaac_version']['dbDependencies'] rescue nil
    end
    version_hash
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
        tomcat_deployments[{url: url, service_name: tomcat.name, service_desc: tomcat.description}] = {}
      else
        if data_hash.has_key? :available
          #   the server is up and available but there are no rails or isaac deployments so we are just returning that the server is available
        else
          data_hash.each do |d|
            context = d.last[:context]
            link = "#{scheme}://#{host}:#{port}#{context}"
            d.last[:link] = link
          end
        end
        $log.trace("Tomcat deployment data_hash is #{data_hash.inspect}")
        tomcat_deployments[{url: url, service_name: tomcat.name, service_desc: tomcat.description, service_id: tomcat.id}] = data_hash
      end
    end

    tomcat_deployments
  end
end
=begin
load './app/controllers/concerns/tomcat_concern.rb'
=end