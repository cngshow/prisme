class UserRoleAssoc < ActiveRecord::Base
  include RoleMetadataConcern
  self.table_name = 'users_roles'
  belongs_to :user
  belongs_to :role
end

=begin
a = User.first.user_role_assocs.first
a.write_metadata?(foo: 'fff')
=end
