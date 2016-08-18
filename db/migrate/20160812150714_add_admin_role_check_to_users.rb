# this migration adds the admin role check column to the users table and adds indexes for both
# the users and ssoi_users tables for this column for searching purposes
class AddAdminRoleCheckToUsers < ActiveRecord::Migration
  def change
    add_column :users, :admin_role_check, :boolean, null: false, default: false

    add_index(:users, [ :admin_role_check, :email ])
    add_index(:ssoi_users, [ :admin_role_check, :ssoi_user_name ])
  end

end
