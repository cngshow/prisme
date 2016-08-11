class CreateSsoiUsers < ActiveRecord::Migration
  def change
    create_table :ssoi_users do |t|
      t.string :ssoi_user_name, null: false
      t.boolean :admin_role_check, null: false, default: false

      t.timestamps null: false
    end
  end
end
