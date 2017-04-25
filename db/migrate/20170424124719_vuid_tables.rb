class VuidTables < ActiveRecord::Migration

  def get_connection
    ora_env = Rails.configuration.database_configuration[Rails.env]
    url = ora_env['url']
    user = ora_env['username']
    pass = ora_env['password']
    java.sql.DriverManager.getConnection(url,user,pass)
  end

  def up
    r_val = create_table(:vuids, id: false) do |t|
      t.integer :next_vuid, null: false
      t.integer :start_vuid, null: false
      t.integer :end_vuid, null: false
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
      proc_sql =  %q{
  CREATE OR REPLACE PROCEDURE PROC_REQUEST_VUID
  (
    A_RANGE IN NUMBER
  , A_USERNAME IN VARCHAR2
  , A_REASON IN VARCHAR2
  , LAST_ID OUT NUMBER
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
      VALUES (-1, 0, 0, sysdate, 'seeding database', 'system');
    end if;

    SELECT count(*)
    INTO v_cnt
    FROM vuids
    where NEXT_VUID > 0;

    IF (v_cnt = 0) THEN
      insert into vuids (NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME)
      VALUES (1, 0, 0, sysdate, 'seeding database', 'system');
      commit;
    end if;

    IF (A_RANGE = 0) THEN
      raise_application_error(-20000, 'Invalid VUID request. The range passed cannot be zero.');
    ELSIF (A_RANGE < 0) then
      select next_vuid
      into v_max_next_vuid
      from vuids
      where ROWNUM = 1
      order by next_vuid asc
      for update;
    ELSE
      select next_vuid
      into v_max_next_vuid
      from vuids
      where ROWNUM = 1
      order by next_vuid desc
      for update;
    END IF;

    if A_RANGE < 0 then
      insert into vuids (NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME)
      VALUES (v_max_next_vuid + A_RANGE, v_max_next_vuid, v_max_next_vuid + A_RANGE + 1, sysdate, A_REASON, A_USERNAME);
      LAST_ID := v_max_next_vuid + A_RANGE;
    else
      insert into vuids (NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME)
      VALUES (v_max_next_vuid + A_RANGE, v_max_next_vuid, v_max_next_vuid + A_RANGE - 1, sysdate, A_REASON, A_USERNAME);
      LAST_ID := v_max_next_vuid + A_RANGE;
    end if;

    commit;

  END PROC_REQUEST_VUID;
}
      begin
        @connection= get_connection
        @statement = @connection.createStatement
        @statement.executeQuery proc_sql
      rescue => ex
        if $log
          $log.error('VUID proc failed to be placed in the DB!')
          $log.error(ex.to_s)
        end
        puts ex.to_s
      ensure
        @statement.close rescue nil#Don't let the initializer fail
        @connection.close rescue nil
      end
    end
    r_val
  end

  def down
    drop_table :vuids, force: :cascade
    get_connection.createStatement.executeQuery %q{drop procedure PROC_REQUEST_VUID}
  end
end
