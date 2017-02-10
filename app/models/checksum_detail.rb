class ChecksumDetail < ActiveRecord::Base
  belongs_to :checksum_request
  belongs_to :va_site

end

=begin
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
  all_sites << {va_site_id: s.id, subset: 'reactants'}
end
cr = ChecksumRequest.new
cd = cr.checksum_details.build all_sites
cr.save #this save also save every single checksum detail


end

=end

