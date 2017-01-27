module JIsaacLibrary
  include_package 'gov.vha.isaac.ochre.deployment.hapi.extension.hl7.message' #HL7CheckSum
  include_package 'gov.vha.isaac.ochre.deployment.model' #Site
  include_package 'gov.vha.isaac.ochre.access.maint.deployment.dto' #PublishMessageDTO
end

module HL7Messaging

  #todo add user to appropriate methods
  module ClassMethods
    def get_check_sum_task(hl7_message_string:, site_list: )
      task = JIsaacLibrary::HL7CheckSum.checkSum(hl7_message_string, site_list)
      task
    end

    def start_checksum_task(task:)
      $log.info("Starting the calculation for the HL7 check sum")
      JIsaacLibrary::WorkExecutors.get().getExecutor().execute(task)
      $log.info("HL7 check sum task started!")
    end

    #convenience method
    def fetch_result(task:)
      JIsaacLibrary.fetch_result(task: task)
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
puts "The result is #{HL7Messaging.fetch_result(task.get)}"


sample hl7 message
MSH^~|\&^VETS MD5^660VM5^XUMF MD5^950^20160825095000.000-0600^^MFQ~M01^62209^T^2.4^^^AL^AL^USA QRD^20160825095000.000-0600^R^I^Standard Terminology Query^^^99999^ALL^Imm Procedures^VA

=end