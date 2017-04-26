module VUID

  VuidResult = Struct.new(:range, :reason, :username, :start_vuid, :end_vuid, :request_datetime, :next_vuid, :error) do
    def get_vuids
      vuids = [start_vuid, end_vuid]
      Range.new(vuids.min, vuids.max).to_a
    end

    def size
      vuids = [start_vuid, end_vuid]
      Range.new(vuids.min, vuids.max).size
    end
  end
  LOCK = Mutex.new
  class <<self

    # results = ActiveRecord::Base.connection.exec_query("select NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME from vuids where username != 'system'")
    # results.to_hash.as_json

    def fetch_rows(num_rows:)
      num_rows = num_rows.to_i rescue 1#prevent sql injection hack
      results = []
      sql =%Q{
                select NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME
                from vuids
                where rownum <= #{num_rows}
                and username != 'system' -- remove seed rows
                order by REQUEST_DATETIME desc
        }
      begin
        result_ar = ActiveRecord::Base.connection.exec_query sql
      rescue => ex
        $log.error("I could not fetch the VUID rows!")
        $log.error ex.to_s
        $log.error(ex.backtrace.join("\n"))
      end
      result_ar&.each do |row|
        sv = row['start_vuid']
        nv = row['end_vuid']
        vuids = [sv, nv]
        range = Range.new(vuids.min, vuids.max).size
        range = -range if sv < 0
        results << VuidResult.new(range, row['request_reason'], row['username'], sv, nv, row['request_datetime'], row['next_vuid'], nil)
      end
      results
    end


    def request_vuid(range:, reason:, username:)
      LOCK.synchronize do
        range = -(range.abs) unless PrismeUtilities.aitc_production?
        next_id = nil
        error = nil
        begin
          if $database.eql?(RailsPrisme::ORACLE)
            conn = nil
            c_stmt = nil
            start_vuid = nil
            end_vuid = nil
            request_datetime = nil
            begin
              conn = get_ora_connection
              c_stmt = conn.prepareCall("{call PROC_REQUEST_VUID(?,?,?,?,?,?,?)}")
              c_stmt.setInt('in_RANGE', range)
              c_stmt.setString('in_REASON', reason)
              c_stmt.setString('in_USERNAME', username)
              c_stmt.registerOutParameter("out_LAST_ID", java.sql.Types::INTEGER)
              c_stmt.registerOutParameter("out_START_VUID", java.sql.Types::INTEGER)
              c_stmt.registerOutParameter("out_END_VUID", java.sql.Types::INTEGER)
              c_stmt.registerOutParameter("out_REQUEST_DATETIME", java.sql.Types::TIMESTAMP)
              c_stmt.execute
              next_id = c_stmt.getInt("out_LAST_ID")
              start_vuid = c_stmt.getInt("out_START_VUID")
              end_vuid = c_stmt.getInt("out_END_VUID")
              request_datetime = c_stmt.getTimestamp("out_REQUEST_DATETIME")
            rescue => ex
              raise ex
            ensure
              c_stmt.close rescue nil
              conn.close rescue nil
            end
          else
            #todo
            #we are H2, implement after we get stored procedure.
          end
        rescue => ex
          error = ex
        end
        time = Time.at(request_datetime.getTime/1000) rescue nil
        VuidResult.new(range, reason, username, start_vuid, end_vuid, time, next_id, error)
      end
    end

    def get_ora_connection
      ora_env = Rails.configuration.database_configuration[Rails.env]
      url = ora_env['url']
      user = ora_env['username']
      pass = ora_env['password']
      properties = java.util.Properties.new
      properties.put("user", user)
      properties.put("password", pass)
      ORACLE_DRIVER.connect(url, properties)
    end
  end
end

=begin
load('./lib/vuid/vuid.rb')
a = VUID.request_vuid(range: 4, reason: 'I am Groot!', username: 'billy')
VUID.fetch_rows(num_rows: 2)

from our driver gem
        begin
            @raw_connection = java.sql.DriverManager.getConnection(url, properties)
          rescue
            # bypass DriverManager to work in cases where ojdbc*.jar
            # is added to the load path at runtime and not on the
            # system classpath
            @raw_connection = ORACLE_DRIVER.connect(url, properties)
=end