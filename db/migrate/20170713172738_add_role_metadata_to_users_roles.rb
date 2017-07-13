class AddRoleMetadataToUsersRoles < ActiveRecord::Migration
  def change
    add_column :users_roles, :role_metadata, :text, required: false
  end
end
