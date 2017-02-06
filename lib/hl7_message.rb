module JIsaacLibrary
  include_package 'gov.vha.isaac.ochre.deployment.hapi.extension.hl7.message' #HL7CheckSum
  include_package 'gov.vha.isaac.ochre.access.maint.deployment.dto' #PublishMessageDTO, SiteDTO
  include_package 'gov.vha.isaac.ochre.services.dto.publish' #HL7ApplicationProperties
end

module HL7Messaging

  ETS_APPLICATION_ID = :ets_application_id
  ETS_SERVER = :ets_server
  INTERFACE_ENGINE_URL = :interface_engine_url
  LISTENER_PORT = :listener_port
  HL7_ENCODING_TYPE = :hl7_encoding_type

  class << self
    #these leak state, you should use the the defined methods unless you know what you are doing...
    attr_accessor :hl7_server_config #hl7_server_config.yml
    attr_accessor :hl7_message_config #hl7_message_config.yml.erb
  end

  #todo add user to appropriate methods
  module ClassMethods
    def get_check_sum_task(hl7_message_string:, site_list:)
      task = JIsaacLibrary::HL7CheckSum.checkSum(hl7_message_string, site_list)
      task
    end

    def start_checksum_task(task:)
      $log.info("Starting the calculation for the HL7 check sum")
      JIsaacLibrary::WorkExecutors.get().getExecutor().execute(task)
      $log.info("HL7 check sum task started!")
    end

    def build_application_props
      props = JIsaacLibrary::HL7ApplicationProperties.new
      hl7_env = PrismeUtilities.hl7_environment[PRISME_ENVIRONMENT]
      props.setApplicationServerName(PRISME_ENVIRONMENT) #See aitc_environment.yml
      props.setApplicationVersion(PRISME_VERSION)
      props.setListenerPort(hl7_env[EVIE_PORT])
      props.setSendingFacilityNamespaceId(hl7_env[ETS_APPLICATION_ID])
      props.setHl7EncodingType("VB")
      props.setEnvironment("")
      props
    end

    #convenience method
    def fetch_result(task:)
      JIsaacLibrary.fetch_result(task: task)
    end

    #see PrismeConstants::ENVIRONMENT for keys
    def server_environment
      return (HashWithIndifferentAccess.new HL7Messaging.hl7_server_config).deep_dup unless HL7Messaging.hl7_server_config.nil?
      HL7Messaging.hl7_server_config = PrismeUtilities.fetch_yml 'hl7/hl7_server_config.yml'
      (HashWithIndifferentAccess.new HL7Messaging.hl7_server_config).deep_dup
    end

    def message_environment
      return (HashWithIndifferentAccess.new HL7Messaging.hl7_message_config).deep_dup unless HL7Messaging.hl7_message_config.nil?
      HL7Messaging.hl7_message_config = PrismeUtilities.fetch_yml 'hl7/hl7_message_config.yml.erb'
      (HashWithIndifferentAccess.new HL7Messaging.hl7_message_config).deep_dup
    end

  end

  extend ClassMethods
end


=begin
load('./lib/hl7_message.rb')

site = JIsaacLibrary::Site.new
pm = JIsaacLibrary::PublishMessageDTO.new(1,site)
hl7_string = 'MSH^~|\&^VETS MD5^660VM5^XUMF MD5^950^20160825095000.000-0600^^MFQ~M01^62209^T^2.4^^^AL^AL^USA QRD^20160825095000.000-0600^R^I^Standard Terminology Query^^^99999^ALL^Imm Procedures^VA'
task = HL7Messaging.get_check_sum_task(hl7_message_string: hl7_string, site_list: [pm])
HL7Messaging.start_checksum_task(task: task)
puts "The result is #{HL7Messaging.fetch_result(task)}"


sample hl7 message
MSH^~|\&^VETS MD5^660VM5^XUMF MD5^950^20160825095000.000-0600^^MFQ~M01^62209^T^2.4^^^AL^AL^USA QRD^20160825095000.000-0600^R^I^Standard Terminology Query^^^99999^ALL^Imm Procedures^VA

=end