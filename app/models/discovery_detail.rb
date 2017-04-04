require './app/models/concerns/HL7Base'

class DiscoveryDetail < ActiveRecord::Base
  include HL7DetailBase
  belongs_to :discovery_request
  belongs_to :va_site
  belongs_to :discovery_detail
  include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishSiteDiscoveryMessage

  alias_method(:request, :discovery_request)

  #For checksum our naming is a little out of sync with discovery.  The referenced detail id is detail_id not checksum_detail_id.  Discovery is discovery_detail_id
  def last_discovery(save_me = true)
    last_detail(discovery_detail_id, :last_discovery_detail, :discovery_detail_id, save_me)
  end

  # csv = DiscoveryRequest.all.first.details.first.to_csv
  # test this ID 10106 with next jar
  def to_csv
    return 'unknown id' if self.id.nil?
    return 'No HL7' if hl7_message.nil?
    HL7Messaging.discovery_hl7_to_csv(discovery_hl7: hl7_message)
  end


end
=begin
load('./app/models/discovery_detail.rb')
=end