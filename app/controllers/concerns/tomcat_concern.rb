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

  def get_connection(service_or_id:, timeout: 0)
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
        faraday.options.timeout = timeout unless (timeout == 0)
      end
    else
      raise StandardError.new('Invalid tomcat service passed to TomcatConcern.get_deployments!')
    end
    conn
  end

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
    if @change_state_succeded
      TomcatUtility::TomcatDeploymentsCache.instance.do_work
    end
    response.body.strip
  end

  private

  # this method is called from app deployer to see if a given application context is already deployed on this server
  def is_context_deployed?
    ret = {status: 'failed', text_color: 'red', message: 'Failed to retrieve application deployment information in order to validate deployed context.<br>Is the Tomcat server instance up and running?'}
    app_label = params['app_label']
    app_context = params['app_context']
    tomcat_id = params['tomcat_id']
    tomcat_service = Service.find(tomcat_id) rescue nil

    if tomcat_service
      tomcat_label = tomcat_service.name
      deployments = TomcatUtility::TomcatDeploymentsCache.instance.get_cached_deployments[tomcat_service.id]
      if deployments&.empty?
        $log.warn('Tomcat Deployments cache is nil, refetching...')
        TomcatUtility::TomcatDeploymentsCache.instance.do_work
        deployments = TomcatUtility::TomcatDeploymentsCache.instance.get_cached_deployments[tomcat_service.id]
      end

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

  def tomcat_server_deployments
    # retrieve tomcat services
    tomcats = Service.get_application_servers
    tomcat_deployments = {}

    # iterate and make faraday call to get the text/list
    tomcats.each do |tomcat|
      data_hash = TomcatUtility::TomcatDeploymentsCache.instance.get_cached_deployments[tomcat.id]
      if (data_hash.nil? || data_hash&.empty?)
        $log.warn('Tomcat Deployments cache is nil (or empty), refetching...')
        TomcatUtility::TomcatDeploymentsCache.instance.do_work
        data_hash = TomcatUtility::TomcatDeploymentsCache.instance.get_cached_deployments[tomcat.id]
      end

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