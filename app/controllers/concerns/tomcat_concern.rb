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
      [$log, $alog].each {|l| l.warn("Unexpected Exception: #{ex.message}")}
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

  # this method is called from app deployer to see if a given application context is already deployed on this server
  def is_context_deployed?
    ret = {status: 'failed', text_color: 'red', message: 'Failed to retrieve application deployment information in order to validate deployed context.<br>Is the Tomcat server instance up and running?'}
    app_label = params['app_label']
    app_context = params['app_context']
    tomcat_id = params['tomcat_id']
    tomcat_service = Service.find(tomcat_id) rescue nil

    if tomcat_service
      tomcat_label = tomcat_service.name
      deployments = get_deployments(tomcat_service: tomcat_id)

      unless deployments.has_key? :failed
        if deployments.has_key? app_context
          ret = {status: 'warn', text_color: 'red', message: %Q{<i class="fa fa-warning" aria-hidden="true"></i>&nbsp;The application #{app_label} has already been deployed on #{tomcat_label}<br>&nbsp;and will be overwritten.}}
        else
          ret = {status: 'success', text_color: 'green', message: %Q{<i class="fa fa-check" aria-hidden="true"></i>&nbsp;OK - The application #{app_label} is valid<br>&nbsp;and is not currently deployed on #{tomcat_label}.}}
        end
      end
    else
      ret = {status: 'failed', text_color: 'red', message: 'Invalid Tomcat server key passed. The application deployment information could not be validated.'}
    end
    ret
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
      # {"isaac-rest-billy_goat-local"=>{:context=>"/isaac-rest-billy_goat-local", :state=>"running", :session_count=>"0", :version=>"1.32", :isaac=>{:database=>{"@class"=>"gov.vha.isaac.rest.api1.data.systeminfo.RestDependencyInfo", "groupId"=>"gov.vha.isaac.db", "artifactId"=>"solor", "version"=>"1.3", "classifier"=>"all", "type"=>"cradle.zip"}, :database_dependencies=>[{"@class"=>"gov.vha.isaac.rest.api1.data.systeminfo.RestDependencyInfo", "groupId"=>"gov.vha.isaac.ochre.modules", "artifactId"=>"ochre-metadata", "version"=>"3.28", "classifier"=>"all", "type"=>"ibdf.zip"}, {"@class"=>"gov.vha.isaac.rest.api1.data.systeminfo.RestDependencyInfo", "groupId"=>"gov.vha.isaac.terminology.converted", "artifactId"=>"rf2-ibdf-sct", "version"=>"${snomed.version}", "classifier"=>"${snomed.classifier}", "type"=>"ibdf.zip"}, {"@class"=>"gov.vha.isaac.rest.api1.data.systeminfo.RestDependencyInfo", "groupId"=>"gov.vha.isaac.terminology.converted", "artifactId"=>"rf2-ibdf-us-extension", "version"=>"${usextension.version}", "classifier"=>"Full", "type"=>"ibdf.zip"}, {"@class"=>"gov.vha.isaac.rest.api1.data.systeminfo.RestDependencyInfo", "groupId"=>"gov.vha.isaac.terminology.converted", "artifactId"=>"loinc-ibdf-tech-preview", "version"=>"${loinc.version}", "type"=>"ibdf.zip"}, {"@class"=>"gov.vha.isaac.rest.api1.data.systeminfo.RestDependencyInfo", "groupId"=>"gov.vha.isaac.terminology.converted", "artifactId"=>"rxnorm-ibdf", "version"=>"${rxnorm.version}", "type"=>"ibdf.zip"}]}, :war_id=>nil}, "rails_komet_b"=>{:context=>"/rails_komet_b", :state=>"running", :session_count=>"0", :version=>"INVALID_JSON", :isaac=>{:isaac_version=>"unknown isaac version", :war_id=>nil, :database=>nil, :database_dependencies=>nil}, :komets_isaac_version=>"unknown isaac version", :war_id=>nil}, "rails_komet_a"=>{:context=>"/rails_komet_a", :state=>"running", :session_count=>"0", :version=>"INVALID_JSON", :isaac=>{:isaac_version=>"unknown isaac version", :war_id=>nil, :database=>nil, :database_dependencies=>nil}, :komets_isaac_version=>"unknown isaac version", :war_id=>nil}}

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