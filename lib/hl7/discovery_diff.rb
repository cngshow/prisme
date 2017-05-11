require 'csv'
module HL7Messaging

  class DiscoveryCsv

    ACTIVE_FLAG = :'1'
    INACTIVE_FLAG = :'0'
    TERM = :Term
    DESIGNATION_NAME = :designation_name

    attr_reader :discovery_data, :headers

    def initialize(hl7_csv_string:, ignore_inactive: false)
      @discovery_data = hl7_csv_string.split("\n").map do |line|
        parsed = CSV.parse_line(line) rescue CSV.parse_line(line.gsub("\"", '|'), quote_char: '|')
        parsed = parsed.map(&:strip).map do |e|
          e.gsub('"', '')
        end.map(&:to_sym)
        parsed
      end
      @headers = @discovery_data.shift
      raise ArgumentError.new('Invalid hl7_csv_string. Status header is missing.') unless headers.last.to_s.casecmp('status').zero?
      raise ArgumentError.new('Invalid hl7_csv_string. VUID header is missing.') unless headers.first.to_s.casecmp('vuid').zero?
      @discovery_data.reject! do |e|
        e.last == INACTIVE_FLAG
      end if ignore_inactive
      @discovery_data.sort! do |a, b|
        a.first <=> b.first
      end
      discovery_data.freeze
      headers.freeze
    end

    #returns a discovery csv
    # common vuid diff count variable makes a weak attempt to find common vuids.  The smaller your csv the less likely you get that many.
    #right_diff_count, common_vuid_diff_count is up to that number, common_vuid_same_count is 0 - number
    def diff_mock(right_diff_count: 10, common_vuid_diff_count: 10, common_vuid_same_count: 10)
      mock = DiscoveryCsv.new(hl7_csv_string: 'vuid,alpha,beta,status')
      mock_discovery_data_right = []
      common_discovery_data = []
      seen_vuids = {}
      right_diff_count.times do
        mock_discovery_data_right << mock_new_elems
      end
      common_vuid_diff_count.times do
        e = Array.new discovery_data.sample
        e[2] = (e[2].to_s + '_different').to_sym if e[2]
        e[3] = (e[3].to_s + '_different').to_sym if e[3]
        e[4] = (e[4].to_s + '_different').to_sym if (e[4] && rand(2).eql?(1) && (e.last != e[4]))#don't change if we are the status field.(last is always status)
        common_discovery_data << e unless seen_vuids[e.first]
        seen_vuids[e.first] = true
      end
      common_vuid_same_count.times do
        e = Array.new discovery_data.sample
        common_discovery_data << e unless seen_vuids[e.first]
        seen_vuids[e.first] = true
      end
      mock.set_headers headers
      mock.set_discovery_data(common_discovery_data + mock_discovery_data_right)
      self.to_tmp_file('original.csv')
      mock.to_tmp_file('mock.csv')
      mock
    end

    def fetch_diffs(discovery_csv:)
      raise ArgumentError.new('Discovery CSV object cannot be nil!') if discovery_csv.nil?
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

    def to_tmp_file(name)
      begin
      content = headers.map do |e|
        "\"#{e}\""
      end.join(',') + "\n"
      discovery_data.each do |line|
        line = line.map do |e|
          "\"#{e}\""
        end
        line = line.join(',') + "\n"
        content << line
      end
      File.write("./tmp/#{name}", content)
      rescue =>ex
        $log.warn("The Diff file #{name} could not be written. #{ex}") if $log #automated unit test will not have a logger
      end
    end

    protected

    def mock_new_elems()
      random_elem = Array.new discovery_data.sample
      r_string = '_' + [*('a'..'z'), *('0'..'9')].shuffle[0, 8].join
      random_elem[0] = (random_elem[0].to_s + r_string +'_m').to_sym
      random_elem
    end

    def set_headers(headers)
      @headers = headers
    end

    def set_discovery_data(data)
      @discovery_data = data
    end

    public

    class DiscoveryDiffs

      attr_reader :current, :comparing

      def initialize(discovery_one_current, discovery_two_comparing)
        @current = discovery_one_current
        @comparing = discovery_two_comparing
        @current_term_index = discovery_one_current.headers.find_index(DiscoveryCsv::TERM)
        @comparing_term_index = discovery_two_comparing.headers.find_index(DiscoveryCsv::TERM)
        @current_vuids = current.discovery_data.map(&:first)
        @comparing_vuids = comparing.discovery_data.map(&:first)
        @left_only_vuids = @current_vuids - @comparing_vuids
        @right_only_vuids = @comparing_vuids - @current_vuids
        @common_vuids = @current_vuids & @comparing_vuids
        @different_common_rows = []
        @common_vuids.each do |vuid|
          current_row = @current.discovery_data.select do |row|
            row.first.eql? vuid
          end.first
          comparing_row = @comparing.discovery_data.select do |row|
            row.first.eql? vuid
          end.first
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
          term = current_row[@current_term_index]
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
            @diff_data[vuid][header] << nil
            @diff_data[vuid][header] << comparing_row_hash[header]
          end
          @diff_data[vuid][DiscoveryCsv::DESIGNATION_NAME] = term
        end
      end

      def left_new_row(vuid)
        @current.discovery_data.select do |row|
          row.first.eql? vuid
        end.first
      end

      def right_new_row(vuid)
        @comparing.discovery_data.select do |row|
          row.first.eql? vuid
        end.first
      end

      def headers_aligned?
        @current.headers.eql? @comparing.headers
      end

      #the diff data structure
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

Fetch diff with mocks:
load('./lib/hl7/discovery_diff.rb')
@alpha_1 = DiscoveryCsv.new(hl7_csv_string: alpha_1_string)
m = @alpha_1.diff_mock(right_diff_count:1, common_vuid_diff_count: 1, common_vuid_same_count: 1)
@alpha_1.fetch_diffs(discovery_csv: m).diff
#at this point check /tmp and diff
=end