module PrismeJars
  def self.load
    jars = Dir.glob('./lib/jars/*.jar')
    jars.each do |jar|
      require jar
    end
  end
end