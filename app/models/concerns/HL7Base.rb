module HL7RequestBase

  def sql_template(domain, subset, site_id, base_table, data_column, my_id)
    my_id = -1 unless my_id
    sql = %(
    select nvl(max(a.id),-1) as last_detail_id
    from #{base_table}_DETAILS a, #{base_table}_REQUESTS b
    where a.#{base_table}_REQUEST_ID = b.id
    and   b.domain = '#{domain}'
    and   a.SUBSET = '#{subset}'
    and   a.VA_SITE_ID = '#{site_id}'
    and   a.id != #{my_id}
    )

    if my_id != -1
      sql << %(
        and   a.id < #{my_id}
        and   a.FINISH_TIME is not null
        and   a.#{data_column} is not null
      )
    end
    sql
  end

  def save_with_details(request:)
    request.class.send(:transaction) do
      request.save!
    end
  end

  def kick_off_task(request:)
    raise 'Not yet implemented!'
  end
end

module HL7RequestSerializer

  def self.included(base)
    base.extend(ClassMethods) #allows: ChecksumRequest.to_record...
  end

  def to_hash
    h = {}
    h['request'] = JSON.parse self.to_json
    h['details'] = JSON.parse self.details.to_json
    h['class'] = self.class.to_s
    h
  end

  module ClassMethods
    def to_record(**hash)
      request = Object.const_get(hash['class']).send(:new, hash['request']) #calls like this ChecksumRequest.to_record DiscoveryRequest.all.first.to_hash do the right thing
      request.details.build hash['details']
      request
    end
  end

  extend ClassMethods #allows 'HL7RequestSerializer.to_record(h)'
end

module HL7DetailBase
  include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishMessage
  include JavaImmutable
  include JIsaacLibrary::Task



  protected

  def last_detail(detail_id, last_detail_method, column_name_id, save_me = true)
    unless detail_id
      last_id = request.class.send(last_detail_method, request.domain, subset, va_site_id, self.id)
      return nil if last_id == -1
      self[column_name_id] = last_id
      save if save_me
    end
    self.class.send(:find, self[column_name_id])
  end


  public

  #if the underlying task is complete we are dun!
  #if the id is nil we are an in memory poro.  We will never start, so we are dun.
  def done?
    r_val = self.id.nil? || [SUCCEEDED, CANCELLED, FAILED].map(&:to_s).include?(self.status)
    $log.debug {"done is returning  #{r_val}"}
    r_val
  end

  # Java methods
  def getMessageId
    self.id
  end

  def getSite
    self.va_site
  end

  def getSubset
    self.subset
  end #THIS IS PART OF DISCOVERY!!!!!!!!!!!!!!!!!!!!!

  def setRawHL7Message(hl7_string)
    self.hl7_message= hl7_string
  end #called for both discovery and checksum

  def getRawHL7Message
    self.hl7_message
  end


end

#Common request methods (CheckSumRequest, ChecksumDetail)
module HL7RequestCommon

end
=begin
load('./app/models/concerns/HL7Base.rb')
=end