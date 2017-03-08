require './app/models/HL7Base'

class ChecksumRequest < ActiveRecord::Base
  extend HL7RequestBase
  has_many :checksum_details, :dependent => :destroy

  alias_method(:details, :checksum_details)

  def self.last_checksum_detail(domain, subset, site_id)
    sql = sql_template(domain, subset, site_id, 'CHECKSUM', 'checksum')
    ChecksumRequest.connection.select_all(sql).first['last_detail_id']
  end

end

=begin
load('./app/models/checksum_request.rb')

Post.find_by_sql "SELECT p.title, c.author FROM posts p, comments c WHERE p.id = c.post_id"

=end
