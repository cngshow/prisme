class Service < ActiveRecord::Base
  has_many :service_properties, :dependent => :destroy

  accepts_nested_attributes_for :service_properties, :reject_if => lambda { |a| a[:value].blank? }, :allow_destroy => true
  validates_uniqueness_of :name

  class << self
    #put class methods here...

    def get_git
      Service.find_by!(service_type: PrismeService::GIT)
    end

    def get_git_props
      hash = get_git.properties_hash
      hash
    end

    def get_artifactory_props
      hash = get_artifactory.properties_hash
      hash[PrismeService::NEXUS_ROOT] = URI(hash[PrismeService::NEXUS_REPOSITORY_URL]).base_url
      hash
    end

    def get_artifactory
      Service.find_by!(service_type: PrismeService::NEXUS) #ActiveRecordNotFound Will be raised if a Nexus is not configured
    end

    def get_build_server_props
      get_build_server.properties_hash
    end

    def get_build_server
      Service.find_by!(service_type: PrismeService::JENKINS)
    end

    def get_application_servers
      Service.where(service_type: PrismeService::TOMCAT)
    end

    def get_application_servers_props
      props = {}
      props[PrismeService::TOMCAT] = []
      get_application_servers.each do |app_server|
        props[PrismeService::TOMCAT] << app_server.properties_hash
      end
      props
    end

    def get_all_services_props
      props = {}
      props[PrismeService::GIT] = Service.get_git_props
      props[PrismeService::NEXUS] = Service.get_artifactory_props
      props[PrismeService::JENKINS] = Service.get_build_server_props
      props.merge!(Service.get_application_servers_props)
    end

    def service_exists?(service_type)
      @@exists_hash ||= {}
      @@exists_hash[service_type] = Service.exists?(service_type: service_type ) unless @@exists_hash[service_type] #once you exist you always exist (or we have a big bug)
      @@exists_hash[service_type]
    end

  end

  #if property is encrypted it is decrypted
  def properties_hash
    hash = {}
    password_keys = $SERVICE_TYPES[self.service_type][PrismeService::TYPE_PROPS].reject do |e| !e[PrismeService::TYPE_TYPE].eql? PrismeService::TYPE_PASSWORD end.map do |e| e['key'] end
    self.service_properties.each do |sp|
      key = sp.key
      value = sp.value
      if (password_keys.include?(key))
        value = CipherSupport.instance.decrypt(encrypted_string: value)
      end
      hash[key] = value unless (value.nil? || value.empty?)
    end
    inferred_properties(hash)
    hash
  end

  private

  # useful for adding inferred properties in non singleton Services.
  def inferred_properties(hash)
    service_type = self.service_type
    case service_type
      when PrismeService::TOMCAT
        self.service_properties.each do |sp|
          if (sp.key.eql?(PrismeService::CARGO_REMOTE_URL))
            url = sp.value
            hash[PrismeService::CARGO_HOSTNAME] = (URI url).host
            hash[PrismeService::CARGO_SERVLET_PORT] = ((URI url).port).to_s
          end
        end
    end
  end

end
# load('./app/models/service.rb')
# a= Service.get_artifactory
# p = a.service_properties
# p[0].service
# p[0].service.service_type
# $SERVICE_TYPES[p[0].service.service_type]
# $SERVICE_TYPES[p[0].service.service_type]['props'].reject do |e| !e['key'].eql?p[0].key end.first['type']
# a = Service.get_application_servers
#  a[0].properties_hash