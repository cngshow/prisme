module HL7RequestBase

  def sql_template(domain, subset, site_id, base_table, data_column)
    %(
    select max(a.id) as last_detail_id
    from #{base_table}_DETAILS a, #{base_table}_REQUESTS b
    where a.#{base_table}_REQUEST_ID = b.id
    and   b.domain = '#{domain}'
    and   a.FINISH_TIME is not null
    and   a.SUBSET = '#{subset}'
    and   a.VA_SITE_ID = '#{site_id}'
    and   a.#{data_column} is not null
    )
  end

end


module HL7DetailBase
  include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishMessage
  include JavaImmutable
  include JIsaacLibrary::Task



#   ChecksumRequest.all.first.checksum_details.first.last_checksum
  protected

  def last_detail(detail_id, last_detail_method, column_name_id)
    unless detail_id
      id = request.class.send(last_detail_method, request.domain, subset, va_site_id)
      return nil if id.nil?
      self[column_name_id] = id
      save
    end
    return self.class.send(:find, self[column_name_id])
  end


  def last_checksum_delete_me
    unless checksum_detail_id
      id = ChecksumRequest.last_checksum_detail(domain: checksum_request.domain, subset: subset, site_id: va_site_id)
      return nil if id.nil?
      self.checksum_detail_id = id
      save
    end
    return ChecksumDetail.find checksum_detail_id
  end


  public

  #if the underlying task is complete we are dun!
  def done?
    [SUCCEEDED, CANCELLED, FAILED].map(&:to_s).include?(self.status)
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
=begin
load('./app/models/HL7Base.rb')
=end