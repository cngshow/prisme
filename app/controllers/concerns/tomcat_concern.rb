require 'faraday'

module TomcatConcern
  def get_deployments(url: url, username: username, pwd: pwd)
    conn = Faraday.new(url: url) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.use Faraday::Response::Logger, $log
      faraday.adapter :net_http # make requests with Net::HTTP
      faraday.basic_auth(username, pwd)
    end

    # get the list of deployed applications
    response = nil

    begin
      response = conn.get('/manager/text/list', {})
    rescue Faraday::ConnectionFailed => ex
      return {failed: ex.message}
    end

    if (response.status.eql?(200))
      data = response.body

      # Sample data format returned
=begin
      OK - Listed applications for virtual host localhost
      /isaac-rest:running:0:isaac-rest
      /:running:0:ROOT
      /rails_komet-1.3-a:running:0:rails_komet-1.3-a
      /rails_komet-1.3-b:stopped:0:rails_komet-1.3-b
      /rails_komet_a:running:0:rails_komet_a
      /host-manager:running:0:/usr/share/tomcat7-admin/host-manager
      /cargo_deploy:running:0:cargo_deploy
      /isaac-rest-1.0.1:running:0:isaac-rest-1.0.1
      /manager:running:2:/usr/share/tomcat7-admin/manager
      /isaac-rest-1.0:running:0:isaac-rest-1.0
=end

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
end
