class ServiceProperty < ActiveRecord::Base
  belongs_to :service

  scope :ordered_props, -> {
    order('service_id ASC, order_idx ASC')
  }
end
