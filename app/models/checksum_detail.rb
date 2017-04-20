require './app/models/concerns/HL7Base'
class ChecksumDetail < ActiveRecord::Base
  include HL7DetailBase
  belongs_to :checksum_request
  belongs_to :va_site
  belongs_to :checksum_detail
  include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishChecksumMessage

  alias_method(:request, :checksum_request)

  def last_checksum(save_me = true)
    last_detail(checksum_detail_id,:last_checksum_detail, :checksum_detail_id, save_me)
  end

  #Java methods here:

  def setVersion(version)
    self.version= version
  end

  def setChecksum(md5_string)
    self.checksum = md5_string
  end #not part of discovery


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

