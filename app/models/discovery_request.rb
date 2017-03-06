require './app/models/HL7Base'

class DiscoveryRequest < ActiveRecord::Base
  has_many :discovery_details, :dependent => :destroy

  alias_method(:details, :discovery_details)

  def self.last_discovery_detail(domain, subset, site_id)
    sql = sql_template(domain, subset, site_id, 'DISCOVERY', 'hl7_message')
    DiscoveryRequest.connection.select_all(sql).first['last_discovery_detail']
  end

end
