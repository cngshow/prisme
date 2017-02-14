class ChecksumRequest < ActiveRecord::Base
  has_many :checksum_details, :dependent => :destroy


  def self.last_checksum_detail(subset_group:, subset:, site_id:)

    sql = %(
    select max(a.id) as last_checksum_detail
    from CHECKSUM_DETAILS a, CHECKSUM_REQUESTS b
    where a.CHECKSUM_REQUEST_ID = b.id
    and   b.SUBSET_GROUP = '#{subset_group}'
    and   b.FINISH_TIME is not null
    and   a.SUBSET = '#{subset}'
    and   a.VA_SITE_ID = '#{site_id}'
    and   a.checksum is not null
    )
    ChecksumRequest.connection.select_all(sql).first['last_checksum_detail']
  end
end

=begin
load('./app/models/checksum_request.rb')

Post.find_by_sql "SELECT p.title, c.author FROM posts p, comments c WHERE p.id = c.post_id"

=end
