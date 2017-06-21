require './lib/deployer/nexus_concern'

class DeployerSupport
  include Singleton
  include NexusConcern

  attr_reader :komet_wars, :isaac_wars, :isaac_dbs

  private
  def initialize
    @komet_wars = get_nexus_wars(app: 'KOMET')
    @isaac_wars = get_nexus_wars(app: 'ISAAC')
    @isaac_dbs = get_isaac_cradle_zips
  end
end


=begin
load('./lib/deployer/deployer.rb')
=end
