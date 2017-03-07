require './app/models/HL7Base'

class DiscoveryDetail < ActiveRecord::Base
  include HL7DetailBase
  belongs_to :discovery_request
  belongs_to :va_site
  belongs_to :discovery_detail
  include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishSiteDiscoveryMessage

  alias_method(:request, :discovery_request)

  def last_discovery
    last_detail(discovery_detail_id, :last_discovery_detail, :discovery_detail_id)
  end


end
=begin
load('./app/models/discovery_detail.rb')
=end