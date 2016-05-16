require 'faraday'
require 'uri'

module TomcatConcern

  STOP = :stop
  UNDEPLOY = :undeploy
  START = :start

# change_state(url: "http://localhost:8080/",username: "devtest",pwd: "devtest", context: "rails_komet_b", state: STOP)
  def change_state(url:, username:, pwd:, context:, state:)
    context = '/' + context unless context[0].eql?('/')

    conn = get_connection(url: url, username: username, pwd: pwd)
    begin
      response = conn.get("/manager/text/#{state}", {path: context})
    rescue Faraday::ConnectionFailed => ex
      $log.warn("Tomcat is unreachable! #{ex.message}")
      return {failed: ex.message}
    end
    response.body
  end

  def get_deployments(url:, username:, pwd:)

    conn = get_connection(url, username, pwd)
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
        war = vars[3]
        ret_hash[war] = {}
        ret_hash[war][:context] = vars[0]
        ret_hash[war][:state] = vars[1]
        ret_hash[war][:session_count] = vars[2]
      end
      return ret_hash
    else
      return {failed: response.body}
    end
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
