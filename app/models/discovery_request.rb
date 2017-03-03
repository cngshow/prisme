class DiscoveryRequest < ActiveRecord::Base
  has_many :discovery_details, :dependent => :destroy

  def self.last_discovery_detail(domain:, subset:, site_id:)

    sql = %(
    select max(a.id) as last_discovery_detail
    from DISCOVERY_DETAILS a, DISCOVERY_REQUESTS b
    where a.DISCOVERY_REQUEST_ID = b.id
    and   b.domain = '#{domain}'
    and   a.FINISH_TIME is not null
    and   a.SUBSET = '#{subset}'
    and   a.VA_SITE_ID = '#{site_id}'
    and   a.hl7_message is not null
    )
    DiscoveryRequest.connection.select_all(sql).first['last_discovery_detail']
  end

end
