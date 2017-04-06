got_it = require 'CSV'
puts "CRIS CRIS -- I GOT IT #{got_it}"
module HL7Messaging

  class DiscoveryCsv

    ACTIVE_FLAG = :"1"
    INACTIVE_FLAG = :"0"

    attr_reader :discovery_data, :headers

    def initialize(hl7_csv_string:)
      @discovery_data = hl7_csv_string.split("\n").map do |e| (CSV.parse_line(e)).map(&:strip).map do |e| e.gsub('"', '') end.map(&:to_sym) end
      @headers = @discovery_data.shift
      raise ArgumentError.new("Invalid hl7_csv_string. Status header is missing.") unless headers.last.to_s.casecmp('status').zero?
      raise ArgumentError.new("Invalid hl7_csv_string. VUID header is missing.") unless headers.first.to_s.casecmp('vuid').zero?
      @discovery_data.sort! do |a,b| a.first <=> b.first end
      discovery_data.freeze
      headers.freeze
    end

    def fetch_diffs(discovery_csv:)
      raise ArgumentError.new("Discovery CSV object cannot be nil!") if discovery_csv.nil?
      return nil if self.eql?(discovery_csv)
      return DiscoveryDiffs.new(self, discovery_csv)
    end

    def to_s
      [headers, discovery_data].flatten.to_s
    end

    def inspect
      [headers, discovery_data].flatten.inspect
    end

    def hash
      return @hash if @hash #immutable class
      @hash = 17
      [discovery_data, headers].flatten.each do |element|
        @hash = 31*@hash + element.hash
      end
      @hash
    end

    def eql?(other)
      return false unless other.is_a? DiscoveryCsv
      headers.eql?(other.headers) && discovery_data.eql?(other.discovery_data)
    end

    class DiscoveryDiffs

      attr_reader :discovery_one, :discovery_two

      def initialize(discovery_one:, discovery_two:)
        @discovery_one = discovery_one
        @discovery_two = discovery_two
      end
    end
    #todo finish me
  end

end