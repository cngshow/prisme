module PrismeOracle
  def self.get_ora_connection
    ora_env = Rails.configuration.database_configuration[Rails.env]
    url = ora_env['url']
    user = ora_env['username']
    pass = ora_env['password']
    properties = java.util.Properties.new
    properties.put('user', user)
    properties.put('password', pass)
    ORACLE_DRIVER.connect(url, properties)
  end
end