module VUID

  VuidResults = Struct.new(:range, :reason, :username, :start_vuid, :end_vuid, :request_datetime, :next_id, :error)
  LOCK = Mutex.new
  class <<self

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
        VuidResults.new(range, reason, username, start_vuid, end_vuid, time, next_id, error)
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
=end