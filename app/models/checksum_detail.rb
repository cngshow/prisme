class ChecksumDetail < ActiveRecord::Base
  belongs_to :checksum_request
  belongs_to :va_site
  belongs_to :checksum_detail
  include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishMessage
  include JavaImmutable

  def last_checksum
    unless checksum_detail_id
      id = ChecksumRequest.last_checksum_detail(domain: checksum_request.domain, subset: subset, site_id: va_site_id)
      return nil if id.nil?
      self.checksum_detail_id = id
      save
    end
    return ChecksumDetail.find checksum_detail_id
  end

  #if the underlying task is complete we are dun!
  def done?
    [SUCCEEDED, CANCELLED, FAILED].map(&:to_s).include?(self.status)
  end

  #Java methods here:

  def setVersion(version_string)
    self.version = version
  end  #setVersion will not be part of discovery

  def getMessageId
    self.id
  end

  def getSite
    self.va_site
  end

  def getSubset
    self.subset
  end #THIS IS PART OF DISCOVERY!!!!!!!!!!!!!!!!!!!!!

  # def setSiteDiscoveryData(discover_string)
  #   self.discovery_data = discover_string
  # end  #not part of checksum, part of discovery

  def setCheckSum(md5_string)
    self.checksum = md5_string
  end #not part of discovery

  def setRawHL7Message(hl7_string)

  end #called for both discovery and checksum

end

=begin

load('./app/models/checksum_detail.rb')
h = {'Allergy' => ['Reaction', 'Reactants'], 'Immunizations' => ['Immunization Procedure']}
sites =["443", "444"]
a = HL7Messaging.build_task_active_record(user: 'Cris', subset_hash: h, site_ids_array: sites)
cr = ChecksumRequest.new
cd = cr.checksum_details.build
cd.save
s = VaSite.all.first


cd.va_site_id = s.id
 cd.save
 cr.checksum_details.first.va_site

all_sites_hash = {}
VaSites.all.each do |s|

A full example:

all_sites = []
VaSite.all.to_a.each do |s|
  all_sites << {va_site_id: s.id, subset: 'Reactants'}
end
cr = ChecksumRequest.new
cd = cr.checksum_details.build all_sites
cr.save #this save also save every single checksum detail


end

=end

