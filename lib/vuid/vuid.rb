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

    #todo refactor with a prepared statement
    def fetch_rows(num_rows:)
      num_rows = num_rows.to_i #prevent sql injection hack
      rs = nil
      results = []
      begin
        conn = get_ora_connection
        statement = nil
        sql =%Q{
                select NEXT_VUID, START_VUID, END_VUID, REQUEST_DATETIME, REQUEST_REASON, USERNAME
                from vuids
                where rownum <= #{num_rows}
                and username != 'system' -- remove seed rows
                order by REQUEST_DATETIME desc
        }
        statement = conn.createStatement
        rs = statement.executeQuery sql
        while (rs.next) do
          #:range, :reason, :username, :start_vuid, :end_vuid, :request_datetime, :next_id, :error
          sv = rs.getInt('START_VUID')
          nv = rs.getInt('END_VUID')
          time = Time.at(rs.getTimestamp('REQUEST_DATETIME').getTime/1000)
          vuids = [sv, nv]
          range = Range.new(vuids.min, vuids.max).size
          range = -range if sv < 0
          results << VuidResult.new(range, rs.getString('REQUEST_REASON'), rs.getString('USERNAME'), sv, nv, time, rs.getInt('NEXT_VUID'), nil)
          #:range, :reason, :username, :start_vuid, :end_vuid, :request_datetime, :next_id, :error
        end
      rescue => ex
          $log.error(ex.to_s)
          $log.error(ex.backtrace.join("\n"))
          return []
      ensure
        rs.close rescue nil
        statment.close rescue nil
        conn.close rescue nil
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

    private

    def get_ora_connection
      ora_env = Rails.configuration.database_configuration[Rails.env]
      url = ora_env['url']
      user = ora_env['username']
      pass = ora_env['password']
      java.sql.DriverManager.getConnection(url, user, pass)
    end
  end
end

=begin
load('./lib/vuid/vuid.rb')
VUID.request_vuid(range: 4, reason: 'I am Groot!', username: 'billy')
VUID.fetch_rows(num_rows: 2)
=end