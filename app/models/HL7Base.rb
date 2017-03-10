module HL7RequestBase

  def sql_template(domain, subset, site_id, base_table, data_column, my_id)
    %(
    select max(a.id) as last_detail_id
    from #{base_table}_DETAILS a, #{base_table}_REQUESTS b
    where a.#{base_table}_REQUEST_ID = b.id
    and   b.domain = '#{domain}'
    and   a.FINISH_TIME is not null
    and   a.SUBSET = '#{subset}'
    and   a.VA_SITE_ID = '#{site_id}'
    and   a.#{data_column} is not null
    and   a.id != #{my_id}
    )
  end

end


module HL7DetailBase
  include gov.vha.isaac.ochre.access.maint.deployment.dto.PublishMessage
  include JavaImmutable
  include JIsaacLibrary::Task



  protected

  def last_detail(detail_id, last_detail_method, column_name_id)
    unless detail_id
      last_id = request.class.send(last_detail_method, request.domain, subset, va_site_id, self.id)
      return nil if last_id.nil?
      self[column_name_id] = last_id
      save
    end
    self.class.send(:find, self[column_name_id])
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