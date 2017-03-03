class DiscoveryDetail < ActiveRecord::Base
  belongs_to :discovery_request
  belongs_to :va_site
  belongs_to :discovery_detail
  # include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishMessage
  # include JavaImmutable
  # include JIsaacLibrary::Task

  def last_discovery
    unless discovery_detail_id
      id = DiscoveryRequest.last_discovery_detail(domain: discovery_request.domain, subset: subset, site_id: va_site_id)
      return nil if id.nil?
      self.discovery_detail_id = id
      save
    end

    DiscoveryDetail.find discovery_detail_id
  end

  #if the underlying task is complete we are dun!
  def done?
    [SUCCEEDED, CANCELLED, FAILED].map(&:to_s).include?(self.status)
  end

end
