require 'test/unit'
require './lib/hl7/discovery_diff'

#to run
#rake TEST=./test/unit/lib/discovery_diff_test.rb
#rake test:lib_unit
class DiscoveryDiffTest < Test::Unit::TestCase
  include HL7Messaging

  def setup
    alpha_1_string = File.open('./test/unit/lib/hl7_test_data/discovery_alpha_1.csv').read
    alpha_2_string = File.open('./test/unit/lib/hl7_test_data/discovery_alpha_2.csv').read
    beta_1_string = File.open('./test/unit/lib/hl7_test_data/discovery_beta_1.csv').read
    beta_2_string = File.open('./test/unit/lib/hl7_test_data/discovery_beta_2.csv').read
    @alpha_1 = DiscoveryCsv.new(hl7_csv_string: alpha_1_string)
    @alpha_2 = DiscoveryCsv.new(hl7_csv_string: alpha_2_string)
    @beta_1 = DiscoveryCsv.new(hl7_csv_string: beta_1_string)
    @beta_2 = DiscoveryCsv.new(hl7_csv_string: beta_2_string)
    @same_one =  DiscoveryCsv.new(hl7_csv_string: File.open('./test/unit/lib/hl7_test_data/discovery_same_1.csv').read)
    @same_two =  DiscoveryCsv.new(hl7_csv_string: File.open('./test/unit/lib/hl7_test_data/discovery_same_2.csv').read)
  end

  def test_missing_vuid
    assert_raise ArgumentError do
      DiscoveryCsv.new(hl7_csv_string: File.open('./test/unit/lib/hl7_test_data/discovery_missing_vuid.csv').read)
    end
  end

  def test_missing_status
    assert_raise ArgumentError do
      DiscoveryCsv.new(hl7_csv_string: File.open('./test/unit/lib/hl7_test_data/discovery_missing_status.csv').read)
    end
  end

  def test_not_equal
    assert(! @alpha_1.eql?(@alpha_2), "These very different csv files are not equal but we think they are!")
    assert(! @alpha_2.eql?(@alpha_1), "These very different csv files are not equal but we think they are!")
    assert(! @beta_1.eql?(@beta_2),   "These very different csv files are not equal but we think they are!")
    assert(! @beta_2.eql?(@beta_1),   "These very different csv files are not equal but we think they are!")
    assert(! @alpha_1.eql?(@beta_1),  "These very different csv files are not equal but we think they are!")
    assert(! @beta_1.eql?(@alpha_1),  "These very different csv files are not equal but we think they are!")
    assert(! @beta_2.eql?(@alpha_2),  "These very different csv files are not equal but we think they are!")
    assert(! @beta_1.eql?(@alpha_2),  "These very different csv files are not equal but we think they are!")
  end

  def test_equal
    same = @same_one.eql?(@same_two)
    symmetric = @same_two.eql? @same_one
    assert(same,"These are the same csv's despite the different order")
    assert(symmetric,"eql? method fails symmetry")
  end

  def test_hash
    assert(@same_one.hash == @same_two.hash, "Hash codes for two equal objects aren't the same!")
    hashes = [@alpha_1.hash, @alpha_2.hash, @beta_1.hash, @beta_2.hash].uniq
    assert(hashes.length != 1, "A dicey test since all these hashes could be the same, but this is so unlikely...We really should have more hashes.")
  end

  def test_no_diffs
    assert(@same_one.fetch_diffs(discovery_csv: @same_two).nil?, "There should not be diffs!")
    assert(@same_two.fetch_diffs(discovery_csv: @same_one).nil?, "There should not be diffs!")
  end

  def test_status_field_valid
    leftovers = @alpha_1.discovery_data.clone.map do |e| e.last end.reject do |e| e.eql? HL7Messaging::DiscoveryCsv::ACTIVE_FLAG end
    leftovers.reject! do |e| e.eql? HL7Messaging::DiscoveryCsv::INACTIVE_FLAG end
    assert(leftovers.empty?, "We have invalid statuses in our data!  #{leftovers}")
  end

end