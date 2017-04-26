module VUID

  VuidResults = Struct.new(:range, :reason, :username, :next_id, :error)

  class <<self

    def request_vuid(range:, reason:, username:)
      range = -(range.abs) unless PrismeUtilities.aitc_production?
      next_id = nil
      error = nil
      begin
        if $database.eql?(RailsPrisme::ORACLE)
          coonn = nil
          c_stmt = nil
          begin
            conn = get_ora_connection
            c_stmt = conn.prepareCall("{call PROC_REQUEST_VUID(?,?,?,?)}")
            c_stmt.setInt('A_RANGE', range)
            c_stmt.setString('A_REASON', reason)
            c_stmt.setString('A_USERNAME', username)
            c_stmt.registerOutParameter("LAST_ID", java.sql.Types::INTEGER)
            c_stmt.execute
            next_id = c_stmt.getInt("LAST_ID")
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
      VuidResults.new(range, reason, username, next_id, error)
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