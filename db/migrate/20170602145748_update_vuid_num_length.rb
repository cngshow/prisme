class UpdateVuidNumLength < ActiveRecord::Migration
  def up
    if $database.eql?(RailsPrisme::ORACLE)
      execute %q{TRUNCATE TABLE vuids}
      change_column :vuids, :next_vuid, :integer, :limit => 19
      change_column :vuids, :start_vuid, :integer, :limit => 19
      change_column :vuids, :end_vuid, :integer, :limit => 19
      recompile_vuid_proc
    end
  end

  def down
    if $database.eql?(RailsPrisme::ORACLE)
      change_column :vuids, :next_vuid, :integer, :limit => 38
      change_column :vuids, :start_vuid, :integer, :limit => 38
      change_column :vuids, :end_vuid, :integer, :limit => 38
      recompile_vuid_proc
    end
  end

  private
  def recompile_vuid_proc
    execute 'ALTER PROCEDURE PROC_REQUEST_VUID COMPILE'
  end
end
