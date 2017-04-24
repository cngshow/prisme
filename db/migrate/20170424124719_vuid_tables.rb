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
      trigger_sql =  %q{
        CREATE OR REPLACE TRIGGER vuids_before_insert
        BEFORE INSERT
           ON vuids
           FOR EACH ROW

        DECLARE
           v_max_next_vuid    vuids.next_vuid%TYPE;
           v_next_vuid        vuids.next_vuid%TYPE;

        BEGIN
          -- find the max next vuid
          SELECT max(next_vuid)
          INTO v_max_next_vuid
          FROM vuids;

          --get the calculated next vuid for the record that is about to be inserted
          SELECT next_vuid
          INTO   v_next_vuid
          FROM   vuids
          WHERE  next_vuid=:NEW.next_vuid;

          IF(v_next_vuid <= v_max_next_vuid) THEN
              raise_application_error(-20000, 'Invalid VUID request. The next VUID being inserted into the table has already been requested.'); --to restrict the insertion`.
          END IF;
        END;
      }
      begin
        @connection= get_connection
        @statement = @connection.createStatement
        @statement.executeQuery trigger_sql
      rescue => ex
        if $log
          $log.error("VUID trigger failed to be placed in the DB!")
          $log.error(ex.to_s)
        end
        puts ex.to_s
      ensure
        @statement.close
        @connection.close
      end
    end
    r_val
  end

  def down
    drop_table :vuids, force: :cascade
  end
end
