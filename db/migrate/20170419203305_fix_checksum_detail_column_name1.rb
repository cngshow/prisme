class FixChecksumDetailColumnName1 < ActiveRecord::Migration

  def up
    begin
      rename_column :checksum_details, :detail_id, :checksum_detail_id
    rescue => ex
      puts "The migration to rename the column in table checksum_details failed."
      puts "This may be completely expected if there is a already a column named CHECKSUM_DETAIL_ID"
      puts "#{ex}"
    end
  end

  def down
    begin
      rename_column :checksum_details, :checksum_detail_id, :detail_id
    rescue => ex
      puts "The migration to rename the column in table checksum_details failed."
      puts "This may be completely expected if there is a already a column named DETAIL_ID"
      puts "#{ex}"
    end
  end

end
