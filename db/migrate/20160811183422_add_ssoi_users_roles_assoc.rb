class AddSsoiUsersRolesAssoc < ActiveRecord::Migration
  def change
    create_table(:ssoi_users_roles, :id => false) do |t|
      t.references :ssoi_user
      t.references :role
    end

    add_index(:ssoi_users_roles, [ :ssoi_user_id, :role_id ])
  end
end
