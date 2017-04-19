require 'test/unit'
require './lib/jars'
PrismeJars.load
require './lib/rails_common/util/rescuable'
require './lib/isaac_utilities'
require './lib/hl7/hl7_message' #require me?
require './lib/hl7/discovery_diff' #require me Greg
require('./config/hl7/discovery_mocks/discovery_mock')#require me Greg


#to run
#rake TEST=./test/unit/lib/discovery_diff_test.rb
#rake test:lib_unit
class DiscoveryDiffTest < Test::Unit::TestCase
  include HL7Messaging #mix me in Greg

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

  def test_ignore_inactive
    inactive_active_string = File.open('./test/unit/lib/hl7_test_data/inactive_active.csv').read
    active_only = DiscoveryCsv.new(hl7_csv_string: inactive_active_string, ignore_inactive: true)
    active_and_inactive = DiscoveryCsv.new(hl7_csv_string: inactive_active_string)
    active_only_count = 0
    inactive_only_count = 0
    active_only.discovery_data.each do |e|
      active_only_count +=1 if e.last == HL7Messaging::DiscoveryCsv::ACTIVE_FLAG
      inactive_only_count +=1 if e.last == HL7Messaging::DiscoveryCsv::INACTIVE_FLAG
    end
    assert(inactive_only_count == 0, "Filtering out inactive flags failed. inactive_only_count: #{inactive_only_count}")
    active_only_count = 0
    inactive_only_count = 0
    active_and_inactive.discovery_data.each do |e|
      active_only_count +=1 if e.last == HL7Messaging::DiscoveryCsv::ACTIVE_FLAG
      inactive_only_count +=1 if e.last == HL7Messaging::DiscoveryCsv::INACTIVE_FLAG
    end
    assert(inactive_only_count != 0, "Allowing inactive flags failed. inactive_only_count: #{inactive_only_count}")
    assert(active_only_count != 0, "Allowing active flags failed. active_only_count: #{active_only_count}")
  end

  def test_end_to_end
    rdc = 1
    discoveries = Dir.glob('./config/hl7/discovery_mocks/*.discovery')
    discoveries.each do |disc_file|
      discovery_text = File.open(disc_file, 'rb').read #discovery text is what you find in the model
      csv_string = HL7Messaging.discovery_hl7_to_csv(discovery_hl7: discovery_text) # you will call to_csv off the model.
      hl7_csv = DiscoveryCsv.new(hl7_csv_string: csv_string)
      mock = hl7_csv.diff_mock(right_diff_count: rdc, common_vuid_diff_count: 1, common_vuid_same_count: 1)
      diffs = hl7_csv.fetch_diffs(discovery_csv: mock).diff
      # csv = DiscoveryCsv.new(some_model.to_csv)
      right_count = 0
      diffs.keys.each do |k|
        if diffs[k].is_a? Array
          right_count += 1 if diffs[k].first.eql? :right_only
        end
      end
      assert(right_count <= rdc, "Too many right diffs found, found #{right_count}")
    end
  end
=begin
   #filter lefts out
  #diffs.reject do |k,v| v.first.eql?(:left_only) if v.is_a? Array end

build a diff

require './lib/hl7/discovery_diff' #require me Greg
require('./config/hl7/discovery_mocks/discovery_mock')#require me Greg
include HL7Messaging #mix me in Greg

discoveries = Dir.glob('./config/hl7/discovery_mocks/*.discovery')
reactants = File.open(discoveries.first, 'rb').read
reactions = File.open(discoveries.last, 'rb').read
reactants_csv_string = HL7Messaging.discovery_hl7_to_csv(discovery_hl7: reactants)
reactions_csv_string = HL7Messaging.discovery_hl7_to_csv(discovery_hl7: reactions)
reactants_csv = DiscoveryCsv.new(hl7_csv_string: reactants_csv_string)
reactions_csv = DiscoveryCsv.new(hl7_csv_string: reactions_csv_string)
rdc = 1
#this builds a reactants mock with the same number of columns
reactants_mock = reactants_csv.diff_mock(right_diff_count: rdc, common_vuid_diff_count: 1, common_vuid_same_count: 1)



#get the diff hashes
reactants_against_reactants_diff  = reactants_csv.fetch_diffs(discovery_csv: reactants_mock).diff

#this builds a reactions mock with the same number of columns
reactions_mock = reactions_csv.diff_mock(right_diff_count: rdc, common_vuid_diff_count: 1, common_vuid_same_count: 1)
#different columns (if reactants and reactions have different columns, might need to pick another mock file)
reactants_against_reactions_diff = reactants_csv.fetch_diffs(discovery_csv: reactions_mock).diff

=end
end