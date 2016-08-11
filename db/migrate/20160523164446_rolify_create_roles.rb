class RolifyCreateRoles < ActiveRecord::Migration
  def change
    create_table(:roles) do |t|
      t.string :name, null: false
      t.references :resource, :polymorphic => true

      t.timestamps null: true
    end

    create_table(:users_roles, :id => false) do |t|
      t.references :user
      t.references :role
    end

    create_table(:ssoi_users_roles, :id => false) do |t|
      t.references :ssoi_user
      t.references :role
    end

    add_index(:roles, :name)
    add_index(:roles, [ :name, :resource_type, :resource_id ])
    add_index(:users_roles, [ :user_id, :role_id ])
    add_index(:ssoi_users_roles, [ :ssoi_user_id, :role_id ])
  end
end
