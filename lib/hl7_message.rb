module JIsaacLibrary
  include_package 'gov.vha.isaac.ochre.deployment.hapi.extension.hl7.message' #HL7CheckSum
  include_package 'gov.vha.isaac.ochre.access.maint.deployment.dto' #PublishMessageDTO, SiteDTO
  include_package 'gov.vha.isaac.ochre.services.dto.publish' #HL7ApplicationProperties

  module Task
    READY = javafx.concurrent.Worker::State::READY
    SCHEDULED = javafx.concurrent.Worker::State::SCHEDULED
    RUNNING = javafx.concurrent.Worker::State::RUNNING
    SUCCEEDED = javafx.concurrent.Worker::State::SUCCEEDED
    CANCELLED = javafx.concurrent.Worker::State::CANCELLED
    FAILED = javafx.concurrent.Worker::State::FAILED
  end
end

module HL7Messaging


  class << self
    #these leak state, you should use the the defined methods unless you know what you are doing...
    attr_accessor :hl7_server_config #hl7_server_config.yml
    attr_accessor :hl7_message_config #hl7_message_config.yml.erb
  end

  module ClassMethods
    # task = HL7Messaging.get_check_sum_task(check_sum: 'some_string', site_list: VaSite.all.to_a)
    def get_check_sum_task(checksum_detail_array:)
      @@application_properties ||= HL7Messaging::ApplicationProperties.new
      @@message_properties ||= HL7Messaging::MessageProperties.new
      task = JIsaacLibrary::HL7Checksum.checksum(checksum_detail_array, @@application_properties, @@message_properties)
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

    #this method is called by the controller.
    #subset_hash looks like {'Allergy' => ['Reaction', 'Reactants'], 'Immunizations' => ['Immunization Procedure']}
    def build_task_activesub_record(user:, subset_hash: ,site_ids_array:)
      task_ar_array = []
      site_ids = []
      cr_array = []
      site_ids_array.each do |site_id|
        site_ids << {va_site_id: site_id}
      end
      subset_hash.each_pair do |main_subset, subset_array|
        cr = ChecksumRequest.new
        cr.username = user
        cr.subset_group = main_subset
        subset_array.each do |subset|
          cd_array = cr.checksum_details.build site_ids
          cd_array.each do |cd|
            cd.subset = subset
          end
        end
        cr_array << cr
      end
      ChecksumRequest.transaction do
        cr_array.each(&:save!)
      end
      kick_off_checksums(cr_array)
      cr_array
    end

    private
    def kick_off_checksums(cr_array)
      cr_array.each do |checksum_request|
        #the call to 'to_a' (below) inflates the models.
        task = get_check_sum_task(checksum_detail_array: checksum_request.checksum_details.to_a)
        # Register the observable
        task.stateProperty.addListener(HL7ChecksumObserver.new(checksum_request))
        #start the task
        start_checksum_task(task:task)
      end
    end

  end

  extend ClassMethods

  # p = HL7Messaging::ApplicationProperties.new
  class ApplicationProperties
    include gov.vha.isaac.ochre.services.dto.publish.ApplicationProperties
    include JavaImmutable

    attr_reader :server_environment

    def initialize
      @server_environment = HL7Messaging.server_environment[PRISME_ENVIRONMENT] # PRISME_ENVIRONMENT = dev, sqa, etc
      @server_environment.keys.each do |key|
        method_name = "get#{key.camelize_preserving}".to_sym
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

  class HL7ChecksumObserver < JIsaacLibrary::TaskObserver
    include JIsaacLibrary::Task

    def initialize(checksum_request)
      @checksum_request = checksum_request
    end

    def changed(observable_task, old_value, new_value)
      super observable_task, old_value, new_value
      $log.info("The checksum request #{@checksum_request.inspect} is now #{new_value}!")
      case new_value
        when SUCCEEDED, FAILED, CANCELLED
          @checksum_request.finish_time = Time.now
          saved = @checksum_request.save #save md5 values set by java side
          cs_string = @checksum_request.inspect
          cd_string = @checksum_request.checksum_details.to_a.inspect
          $log.always_n(PrismeLogEvent::CHECKSUM_TAG,"#{cs_string}\n\n#{cd_string}")
          $log.warn("The checksum request #{@checksum_request.inspect} did not save md5 data to the db. (check rails_prisme log)") unless saved
        when RUNNING
          @checksum_request.start_time = Time.now
          saved = (@checksum_request.save)
          $log.warn("The checksum request #{@checksum_request.inspect} is now running, but the field start_time did not save to the db. (check rails_prisme log)") unless saved
        else

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