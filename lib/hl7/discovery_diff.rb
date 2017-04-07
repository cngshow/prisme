require 'csv'
module HL7Messaging

  class DiscoveryCsv

    ACTIVE_FLAG = :"1"
    INACTIVE_FLAG = :"0"

    attr_reader :discovery_data, :headers

    def initialize(hl7_csv_string:)
      @discovery_data = hl7_csv_string.split("\n").map do |e|
        parsed = CSV.parse_line(e) rescue CSV.parse_line(e.gsub("\"", '|'), quote_char: '|')
        (parsed).map(&:strip).map do |e| e.gsub('"', '') end.map(&:to_sym)
      end
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

      attr_reader :current, :comparing

      def initialize(discovery_one_current, discovery_two_comparing)
        @current = discovery_one_current
        @comparing = discovery_two_comparing
        @current_vuids = current.discovery_data.map(&:first)
        @comparing_vuids = comparing.discovery_data.map(&:first)
        @left_only_vuids = @current_vuids - @comparing_vuids
        @right_only_vuids = @comparing_vuids - @current_vuids
        @common_vuids = @current_vuids & @comparing_vuids
        @different_common_rows = []
        @common_vuids.each do |vuid|
          current_row = @current.discovery_data.select do |row| row.first.eql? vuid end.first
          comparing_row = @comparing.discovery_data.select do |row| row.first.eql? vuid end.first
          @different_common_rows << [current_row, comparing_row] unless current_row.eql? comparing_row
        end
        @diff_data = {}
        @left_only_vuids.each do |vuid|
          @diff_data[vuid] = [:left_only, left_new_row(vuid)]
        end
        @right_only_vuids.each do |vuid|
          @diff_data[vuid] = [:right_only, right_new_row(vuid)]
        end
        @different_common_rows.each do |rows|
          current_row = rows.first
          comparing_row = rows.last
          vuid = current_row.first
          current_row_hash = {}
          current.headers.each_with_index do |header, index|
            current_row_hash[header] = current_row[index]
          end
          comparing_row_hash = {}
          comparing.headers.each_with_index do |header, index|
            comparing_row_hash[header] = comparing_row[index]
          end

          common_headers = current_row_hash.keys & comparing_row_hash.keys
          common_headers.each do |header|
            unless (current_row_hash[header].eql?(comparing_row_hash[header]))
              @diff_data[vuid] ||= {}
              @diff_data[vuid][header] ||= []
              @diff_data[vuid][header] << current_row_hash[header]
              @diff_data[vuid][header] << comparing_row_hash[header]
            end
          end
          left_only_headers = current_row_hash.keys - comparing_row_hash.keys
          right_only_headers = comparing_row_hash.keys - current_row_hash.keys
          left_only_headers.each do |header|
            @diff_data[vuid] ||= {}
            @diff_data[vuid][header] ||= []
            @diff_data[vuid][header] << current_row_hash[header]
            @diff_data[vuid][header] << nil
          end
          right_only_headers.each do |header|
            @diff_data[vuid] ||= {}
            @diff_data[vuid][header] ||= []
            @diff_data[vuid][header] <<  nil
            @diff_data[vuid][header] << comparing_row_hash[header]
          end
        end
      end

      def left_new_row(vuid)
        @current.discovery_data.select do |row| row.first.eql? vuid end.first
      end

      def right_new_row(vuid)
        @comparing.discovery_data.select do |row| row.first.eql? vuid end.first
      end

      def headers_aligned?
        @current.headers.eql? @comparing.headers
      end

      #call the methods left and right off of this object.
      def diff
        @diff_data.deep_dup
      end

    end
  end

end

=begin
load('./lib/hl7/discovery_diff.rb')
  include HL7Messaging

    alpha_1_string = File.open('./test/unit/lib/hl7_test_data/discovery_alpha_1.csv').read
    alpha_2_string = File.open('./test/unit/lib/hl7_test_data/discovery_alpha_2.csv').read
    beta_1_string = File.open('./test/unit/lib/hl7_test_data/discovery_beta_1.csv').read
    beta_2_string = File.open('./test/unit/lib/hl7_test_data/discovery_beta_2.csv').read
@beta_1 = DiscoveryCsv.new(hl7_csv_string: beta_1_string)
@beta_2 = DiscoveryCsv.new(hl7_csv_string: beta_2_string)
d = @beta_1.fetch_diffs(discovery_csv: @beta_2)


@alpha_1 = DiscoveryCsv.new(hl7_csv_string: alpha_1_string)
@alpha_2 = DiscoveryCsv.new(hl7_csv_string: alpha_2_string)
d = @alpha_1.fetch_diffs(discovery_csv: @alpha_2)


d = @alpha_1.fetch_diffs(discovery_csv: @beta_2).diff
d[:"5538527"]
=end