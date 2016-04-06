class Service < ActiveRecord::Base
  has_many :service_properties, :dependent => :destroy

  accepts_nested_attributes_for :service_properties, :reject_if => lambda { |a| a[:value].blank? }, :allow_destroy => true


  def properties_hash
    hash = {}
    self.service_properties.each do |sp|
      hash[sp.key] = sp.value unless (sp.value.nil? || sp.value.empty?)
    end
    hash
  end

end
