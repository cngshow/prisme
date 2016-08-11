class Role < ActiveRecord::Base

  # The call to rolify sets up this in the user and ssoi_user models
  # has_and_belongs_to_many :users, :join_table => :users_roles
  # has_and_belongs_to_many :ssoi_users, :join_table => :ssoi_users_roles

  belongs_to :resource,
             :polymorphic => true
             # :optional => true

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true

  scopify
end
