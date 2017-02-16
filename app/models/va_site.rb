class VaSite < ActiveRecord::Base
  include gov.vha.isaac.ochre.access.maint.deployment.dto.Site


  validates_uniqueness_of :va_site_id
  self.primary_key = 'va_site_id'
  include InterestingColumnCompare

  #Java methods here:

  #  VaSite.all.to_a.first.to_java.getId
  def getId
    self.id.to_i rescue -1
  end

  #  VaSite.all.to_a.first.to_java.getGroupName
  def getGroupName
    raise java.lang.UnsupportedOperationException.new("Currently not supported")
  end

  #  VaSite.all.to_a.first.to_java.getName
  def getName
    name
  end

  #alias and alias method are flaky in this case? Why?

  #  VaSite.all.to_a.first.to_java.getType
  def getType
    site_type
  end

  #  VaSite.all.to_a.first.to_java.getVaSiteId
  def getVaSiteId
    va_site_id
  end

  #  VaSite.all.to_a.first.to_java.getMessageType
  def getMessageType
    message_type
  end

  # See opening of site below
  #  And here is an example of a heavily overloaded method that I asked to not be there...
  #  calling it is a PITA...
  #  VaSite.all.to_a.first.to_java.java_send :compareTo, [gov.vha.isaac.ochre.access.maint.deployment.dto.Site], VaSite.all.to_a.last.to_java
  def compareTo(other)
    getName <=> other.getName
  end

end

#load('./app/models/va_site.rb')