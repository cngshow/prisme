class AddRoleMetadata < ActiveRecord::Migration
  def self.up
    [UserRoleAssoc, SsoiUserRoleAssoc].each do |model|
      table_name = model.table_name
      user_id_col_name = model.user_id_col_name

      # squirrel away the data to reload after the new columns are added
      data = model.all.as_json
      execute "TRUNCATE TABLE #{table_name}"

      # add the role_metadata and id columns
      add_column table_name.to_sym, :role_metadata, :text, required: false
      add_column table_name.to_sym, :id, :primary_key

      # reload the table using the data above
      idx = 0
      data.each do |row|
        idx = idx + 1
        execute "insert into #{table_name} (id, #{user_id_col_name}, role_id) values (#{idx},#{row[user_id_col_name]},#{row['role_id']})"
      end
    end
  end

  def self.down
    [UserRoleAssoc, SsoiUserRoleAssoc].each do |model|
      table_name = model.table_name
      remove_column table_name.to_sym, :role_metadata
      remove_column table_name.to_sym, :id
      if $database.eql?(RailsPrisme::ORACLE)
        execute "DROP SEQUENCE #{table_name.upcase}_SEQ"
      end
    end
  end
end
