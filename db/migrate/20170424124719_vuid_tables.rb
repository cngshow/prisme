require './lib/oracle/ora'

class VuidTables < ActiveRecord::Migration

  def up
    r_val = create_table(:vuids, id: false) do |t|
      t.integer :next_vuid, null: false, :limit => 19
      t.integer :start_vuid, null: false, :limit => 19
      t.integer :end_vuid, null: false, :limit => 19
      t.datetime :request_datetime, null: false
      t.text :request_reason
      t.string :username
    end

    execute %q{ALTER TABLE vuids ADD PRIMARY KEY (next_vuid)}
    add_index :vuids, [:start_vuid, :end_vuid], name: 'idx_vuids_start_end'
    add_index :vuids, :request_datetime
    add_index :vuids, :username


    #   if we are in oracle then create a pre-insert trigger that will prevent users from inserting the new record with an invalid vuid (one that has already been requested)
    if $database.eql?(RailsPrisme::ORACLE)
      # -20000 to -20999 for  customized error messages.
      # http://www.oracle.com/technetwork/database/enterprise-edition/parameterized-custom-messages-098893.html
      proc_sql = %q{
  CREATE OR REPLACE PROCEDURE PROC_REQUEST_VUID
  (
    in_RANGE IN NUMBER
  , in_USERNAME IN VARCHAR2
  , in_REASON IN VARCHAR2
  , out_LAST_ID OUT NUMBER
  , out_START_VUID OUT NUMBER
  , out_END_VUID OUT NUMBER
  , out_REQUEST_DATETIME OUT DATE
  )
  IS
    v_cnt              NUMBER;
    v_max_next_vuid    vuids.next_vuid%TYPE;

  BEGIN
    SELECT count(*)
    INTO v_cnt
    FROM vuids
    where NEXT_VUID < 0;

    IF (v_cnt = 0) THEN
      insert into vuids (NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME)
      VALUES (-1, 0, 0, sys_extract_utc(systimestamp), 'seeding database', 'system');
    end if;

    SELECT count(*)
    INTO v_cnt
    FROM vuids
    where NEXT_VUID > 0;

    IF (v_cnt = 0) THEN
      insert into vuids (NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME)
      VALUES (1, 0, 0, sys_extract_utc(systimestamp), 'seeding database', 'system');
    end if;

    IF (in_RANGE = 0) THEN
      raise_application_error(-20000, 'Invalid VUID request. The range passed cannot be zero.');
    ELSIF (in_RANGE < 0) then
      select next_vuid
      into v_max_next_vuid
      from vuids
      where ROWNUM = 1
      order by next_vuid asc
      for update; -- This locks the row!
    ELSE
      select next_vuid
      into v_max_next_vuid
      from vuids
      where ROWNUM = 1
      order by next_vuid desc
      for update; -- This locks the row!
    END IF;

    if in_RANGE < 0 then
      insert into vuids (NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME)
      VALUES (v_max_next_vuid + in_RANGE, v_max_next_vuid, v_max_next_vuid + in_RANGE + 1, sys_extract_utc(systimestamp), in_REASON, in_USERNAME);
      out_LAST_ID := v_max_next_vuid + in_RANGE;
    else
      insert into vuids (NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME)
      VALUES (v_max_next_vuid + in_RANGE, v_max_next_vuid, v_max_next_vuid + in_RANGE - 1, sys_extract_utc(systimestamp), in_REASON, in_USERNAME);
      out_LAST_ID := v_max_next_vuid + in_RANGE;
    end if;

    -- commit the changes to the table to unlock the last id row
    commit;

    SELECT NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME
    INTO out_LAST_ID, out_START_VUID, out_END_VUID, out_REQUEST_DATETIME
    FROM VUIDS
    WHERE NEXT_VUID = out_LAST_ID;

  END PROC_REQUEST_VUID;
}
      begin
        @connection= PrismeOracle.get_ora_connection
        @statement = @connection.createStatement
        @statement.executeQuery proc_sql
      rescue => ex
        if $log
          $log.error('VUID proc failed to be placed in the DB!')
          $log.error(ex.to_s)
        end
        puts ex.to_s
      ensure
        @statement.close rescue nil #Don't let the initializer fail
        @connection.close rescue nil
      end
    end
    r_val
  end

  def down
    drop_table :vuids, force: :cascade
    begin
      PrismeOracle.get_ora_connection.createStatement.executeQuery %q{drop procedure PROC_REQUEST_VUID}
    rescue => ex
      puts "Drop procedure failed! #{ex}"
    end
  end
end

=begin
Example proc call (java side)

load('./db/migrate/20170424124719_vuid_tables.rb')
#con is a jdbc connection
conn = VuidTables.new.get_connection

cStmt = conn.prepareCall("{call PROC_REQUEST_VUID(?,?,?,?)}")
cStmt.setInt('A_RANGE',5)
cStmt.setString('A_REASON','I am Groot!')
cStmt.setString('A_USERNAME',"cshupp")
cStmt.registerOutParameter("LAST_ID",java.sql.Types::INTEGER)
cStmt.execute()
id = cStmt.getInt("LAST_ID")

    A_RANGE IN NUMBER
  , A_USERNAME IN VARCHAR2
  , A_REASON IN VARCHAR2
  , LAST_ID OUT NUMBER
=end
