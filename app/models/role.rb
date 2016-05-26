class Role < ActiveRecord::Base
  # KOMET roles
  KOMET_TERMINOLOGY_EDIT_SOLOR = :'Terminology Edit - SOLOR'
  KOMET_TERMINOLOGY_EDIT_VHAT = :'Terminology Edit - VHAT'
  KOMET_TERMINOLOGY_EDIT_LOINC = :'Terminology Edit - LOINC'
  KOMET_ROLES = [KOMET_TERMINOLOGY_EDIT_SOLOR, KOMET_TERMINOLOGY_EDIT_VHAT, KOMET_TERMINOLOGY_EDIT_LOINC]

  # PRISME roles
  PRISME_ADMIN = :'PRISME - Admin'
  PRISME_ROLES = [PRISME_ADMIN]

  has_and_belongs_to_many :users, :join_table => :users_roles

  belongs_to :resource,
             :polymorphic => true
             # :optional => true

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  scopify

  def is_valid_role?(role)
    KOMET_ROLES.merge(PRISME_ROLES).include? role
  end
end
