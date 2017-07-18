class SsoiUserRoleAssoc < ActiveRecord::Base
  include RoleMetadataConcern
  self.table_name = 'ssoi_users_roles'
  belongs_to :ssoi_user
  belongs_to :role
end
