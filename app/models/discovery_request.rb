require './app/models/concerns/HL7Base'
require './app/models/concerns/cleanup_concern'

class DiscoveryRequest < ActiveRecord::Base
  extend HL7RequestBase, Cleanup
  include HL7RequestSerializer
  has_many :discovery_details, :dependent => :destroy

  alias_method(:details, :discovery_details)

  def self.last_discovery_detail(domain, subset, site_id, my_id)
    sql = sql_template(domain, subset, site_id, 'DISCOVERY', 'hl7_message', my_id)
    DiscoveryRequest.connection.select_all(sql).first['last_detail_id']
  end

end
=begin
load('./app/models/discovery_request.rb')
=end