module JIsaacLibrary
  include_package 'gov.vha.isaac.ochre.deployment.hapi.extension.hl7.message' #HL7CheckSum
  include_package 'gov.vha.isaac.ochre.access.maint.deployment.dto' #PublishMessageDTO, SiteDTO
  include_package 'gov.vha.isaac.ochre.services.dto.publish' #HL7ApplicationProperties
end

module HL7Messaging


  class << self
    #these leak state, you should use the the defined methods unless you know what you are doing...
    attr_accessor :hl7_server_config #hl7_server_config.yml
    attr_accessor :hl7_message_config #hl7_message_config.yml.erb
  end

  #todo add user to appropriate methods
  module ClassMethods
    # task = HL7Messaging.get_check_sum_task(check_sum: 'some_string', site_list: VaSite.all.to_a)
    def get_check_sum_task(subset:, site_list:)
      @@application_properties ||= HL7Messaging::ApplicationProperties.new
      @@message_properties ||= HL7Messaging::MessageProperties.new
      task = JIsaacLibrary::HL7CheckSum.checkSum(subset, site_list, @@application_properties, @@message_properties)
      task
    end

    # HL7Messaging.start_checksum_task(task: task)
    def start_checksum_task(task:)
      $log.info("Starting the calculation for the HL7 check sum")
      JIsaacLibrary::WorkExecutors.get().getExecutor().execute(task)
      $log.info("HL7 check sum task started!")
    end


    #convenience method
    # HL7Messaging.fetch_result(task: task)
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

  # p = HL7Messaging::ApplicationProperties.new
  class ApplicationProperties
    include gov.vha.isaac.ochre.services.dto.publish.ApplicationProperties
    include JavaImmutable

    attr_reader :server_environment

    def initialize
      p "My hostname is #{Socket.gethostname} "
      p "Prisme environment is #{PRISME_ENVIRONMENT}"
      p HL7Messaging.server_environment[PRISME_ENVIRONMENT]
      p '----'
      p HL7Messaging.server_environment
      p 'dun!!!'
      @server_environment = HL7Messaging.server_environment[PRISME_ENVIRONMENT] # PRISME_ENVIRONMENT = dev, sqa, etc
      @server_environment.keys.each do |key|
        method_name = "get#{key.camelize}".to_sym
        self.define_singleton_method(method_name) do
          @server_environment[key]
        end
      end
    end

    def getApplicationServerName
      PRISME_ENVIRONMENT
    end

    def getApplicationVersion
      PRISME_VERSION
    end

    def getInterfaceEngineURL
      java.net.URL.new getInterfaceEngineUrl
    end
  end

  # p = HL7Messaging::MessageProperties.new
  class MessageProperties
    include gov.vha.isaac.ochre.services.dto.publish.MessageProperties
    include JavaImmutable

    attr_reader :message_environment

    def initialize
      @message_environment = HL7Messaging.message_environment
      @message_environment.keys.each do |key|
        method_name = "get#{key.camelize_preserving}".to_sym
        self.define_singleton_method(method_name) do
          @message_environment[key]
        end
      end
    end
  end
end
=begin
p = HL7Messaging::MessageProperties.new
m = p.to_java
m.setVersionId("Development")
m.getVersionId
m.getQueryLimitedRequestUnits

=end
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