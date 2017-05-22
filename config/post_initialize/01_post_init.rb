module PrismeUtilities
  module RouteHelper
    include Rails.application.routes.url_helpers

    def self.route(url_or_path, **params)
      host = PRISME_ENVIRONMENT.eql?(PrismeConstants::ENVIRONMENT::DEV_BOX.to_s) ? 'localhost' : Socket.gethostname
      Rails.application.routes.url_helpers.send(url_or_path.to_sym, {port:PrismeConstants::URL::PORT, protocol: PrismeConstants::URL::SCHEME, host: host, relative_url_root: '/' + PrismeConstants::URL::CONTEXT}.merge(params))
    end
  end

  #only works post init.
  def self.write_vuid_db
    json = Rails.configuration.database_configuration[Rails.env]
    json.merge! PrismeUtilities.fetch_vuid_config
    json.merge!({'epoch_time_seconds' => Time.now.to_i})
    json.merge!({'epoch_time_seconds' => Time.now.to_i})
    json.merge!({'log_events_url' =>  PrismeUtilities::RouteHelper.route(:log_event_url, security_token: CipherSupport.instance.generate_security_token)})
    begin
      json_to_yaml_file(json, VUID_DB_FILE)
    rescue => ex
      $log.error("The file #{VUID_DB_FILE} was not written.  This will impact the vuid server!")
      $log.error(ex.to_s)
      $log.error(ex.backtrace.join("\n"))
    end
  end

end

PrismeUtilities.write_vuid_db
at_exit do
  PrismeUtilities.remove_vuid_db
end