module TomcatUtility

  class TomcatNameBase
    attr_reader :tomcat, :war_uuid

    def initialize(tomcat, war_uuid)
      @tomcat=tomcat
      @war_uuid = war_uuid
      @uuid_prop = UuidProp.find(@war_uuid)
    end

    def get_name
      @uuid_prop&.get(key: UuidProp::Keys::NAME)
    end

  end

  class KometName < TomcatNameBase
    def get_isaac_war_id
      @uuid_prop&.get(key: UuidProp::Keys::DEPENDENT_UUID)
    end

    def get_isaac_prop
      UuidProp.find(get_isaac_war_id) rescue nil
    end

    def get_isaac_name
      get_isaac_prop&.get(key: UuidProp::Keys::NAME)
    end

    def get_isaac_db_uuid
      get_isaac_prop&.get(key: UuidProp::Keys::ISAAC_DB_ID)
    end

  end

  class IsaacName < TomcatNameBase
    attr_accessor :komets

    def initialize(tomcat, war_uuid)
      super tomcat, war_uuid
      @komets = []
    end

    def get_db_uuid
      @uuid_prop&.get(key: UuidProp::Keys::ISAAC_DB_ID)
    end
  end

  class TomcatDeploymentsCache < PrismeCacheManager::ActivitySupport
    include Singleton
    include TomcatConcern

    MATCHER_ISAAC_OR_KOMET_WAR = /^(isaac|rails_k).*/
    MATCHER_ISAAC = /^isaac.*/
    MATCHER_KOMET = /^rails_k.*/

    def get_isaac_deployments
      deployments = get_indifferent_cached_deployments
      komet_uuids = []
      isaac_uuids = []
      deployments.each_pair do |service_id, deployment_hash|
        tomcat_service = Service.find(service_id)
        deployment_hash.keys.each do |key|
          if key =~ MATCHER_KOMET
            komet_uuids << KometName.new(tomcat_service, deployment_hash[key][:war_id]) if deployment_hash[key][:war_id]
          elsif key =~ MATCHER_ISAAC
            isaac_uuids << IsaacName.new(tomcat_service, deployment_hash[key][:war_id]) if deployment_hash[key][:war_id]
          end
        end
      end
      isaac_uuids.each do |i|
        komet_uuids.each do |k|
          if k.get_isaac_war_id.eql?(i.war_uuid)
            i.komets << k
          end
        end
      end
      isaac_uuids
    end

=begin
isaacs = TomcatUtility::TomcatDeploymentsCache.instance.get_isaac_deployments
isaacs.first.tomcat.name
isaacs.first.get_db_uuid
isaacs.first.get_name
isaacs.first.komets.first.get_name
isaacs.first.komets.first.get_isaac_db_uuid #will match with isaacs.first.get_db_uuid
=end
    #same as get_cached_deployments, but hash is indifferent
    def get_indifferent_cached_deployments
      HashWithIndifferentAccess.new get_cached_deployments
    end

    def get_cached_deployments
      @work_lock.synchronize do
        return @deployments.deep_dup
      end
    end

    def do_work
      @work_lock.synchronize do
        $log.debug('I am doing my work!')
        Service.get_application_servers.each do |service|
          @deployments[service.id] = get_deployments(tomcat_service: service)
        end
        $log.debug('I am done!')
      end
    end

    def register
      duration = $PROPS['PRISME.tomcat_deployment_cache'].to_i.minutes
      @worker.register_work('TomcatDeploymentsCache', duration) do
        do_work
      end
    end

    private
    def initialize
      @worker = PrismeCacheManager::CacheWorkerManager.instance.fetch(PrismeCacheManager::TOMCAT_DEPLOY)
      @work_lock = @worker.work_lock
      @deployments = {}
      super(@work_lock)
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
          next unless war =~ MATCHER_ISAAC_OR_KOMET_WAR
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
        isaac_db_id = json[UuidProp::ISAAC_DB_ID].to_s unless json[UuidProp::ISAAC_DB_ID].to_s.empty?
        version_hash[:isaac][:db_id] = isaac_db_id.to_s
        version_hash[:isaac][:database] = json['isaacDbDependency']
        version_hash[:isaac][:database_dependencies] = json['dbDependencies']
        UuidProp.uuid(uuid: version_hash[:war_id], state: state, isaac_db_id: isaac_db_id)
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
  end
end

=begin caution - using this all tomcat data disappears
load('./lib/utilities/tomcat_utility.rb')
=end