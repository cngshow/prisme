class UpdateVuidNumLength < ActiveRecord::Migration
  def up
    if $database.eql?(RailsPrisme::ORACLE)
      execute %q{TRUNCATE TABLE vuids}
      change_column :vuids, :next_vuid, :integer, :limit => 19
      change_column :vuids, :start_vuid, :integer, :limit => 19
      change_column :vuids, :end_vuid, :integer, :limit => 19
    end
  end

  def down
    if $database.eql?(RailsPrisme::ORACLE)
      change_column :vuids, :next_vuid, :integer, :limit => 38
      change_column :vuids, :start_vuid, :integer, :limit => 38
      change_column :vuids, :end_vuid, :integer, :limit => 38
    end
  end
end
