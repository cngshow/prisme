class ChecksumDetail < ActiveRecord::Base
  belongs_to :checksum_request
  belongs_to :va_site
  include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishMessage
  include JavaImmutable

  def last_checksum
    unless checksum_detail_id
      id = ChecksumRequest.last_checksum_detail(subset_group: checksum_request.subset_group, subset: subset, site_id: va_site_id)
      return nil if id.nil?
      self.checksum_detail_id = id
      save
    end
    return ChecksumDetail.find checksum_detail_id
  end

  #Java methods here:
  # def setVersion(version_string)
  #   self.version = version
  # end

  def getMessageId
    self.id
  end

  def getSite
    self.va_site
  end

  def getSubset
    self.subset
  end

  def setSiteDiscoveryData(discover_string)
    self.discovery_data = discover_string
  end

  def setCheckSum(md5_string)
    self.checksum = md5_string
  end


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

