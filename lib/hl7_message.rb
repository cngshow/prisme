module JIsaacLibrary
  include_package 'gov.vha.isaac.ochre.deployment.hapi.extension.hl7.message' #HL7CheckSum
end

module HL7Messaging

  module ClassMethods
    def check_sum(hl7_message_string: )

    end
  end
  extend ClassMethods
end


=begin
load('./lib/hl7_message.rb')
=end