module Mocks
  module Discovery
    def self.fetch_random_discovery
      @@discovery ||= {}
      if @@discovery.empty?
        discoveries = Dir.glob('./config/hl7/discovery_mocks/*.discovery')
        discoveries.each do |disc_file|
          @@discovery[disc_file] = File.open(disc_file, 'rb').read
        end
      end
      @@discovery.values.sample
    end
  end
end

=begin
load './config/hl7/discovery_mocks/discovery_mock.rb'
Mocks::Discovery.fetch_random_discovery
=end