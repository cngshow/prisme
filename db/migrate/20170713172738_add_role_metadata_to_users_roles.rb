class AddRoleMetadataToUsersRoles < ActiveRecord::Migration
  def self.up
    if $database.eql?(RailsPrisme::ORACLE)
      # store off the existing data and truncate the table so we can add the id as the primary key
      data = UserRoleAssoc.all.as_json
      execute %q{TRUNCATE TABLE users_roles}

      # add the role_metadata and id columns
      add_column :users_roles, :role_metadata, :text, required: false
      add_column :users_roles, :id, :primary_key

      # reload the table using the data above
      idx = 0
      data.each do |row|
        idx = idx + 1
        execute "insert into users_roles (id, user_id, role_id) values (#{idx},#{row['user_id']},#{row['role_id']})"
      end
    end
  end

  def self.down
    if $database.eql?(RailsPrisme::ORACLE)
      remove_column :users_roles, :role_metadata
      remove_column :users_roles, :id
      execute %q{DROP SEQUENCE USERS_ROLES_SEQ}
    end
  end
end
