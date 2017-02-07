$testing = true
require 'test_helper'
require './config/initializers/01_prisme_init'

class Hl7MessagingTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  def setup
    @subset_string='some_string'
  end

  def tear_down
    java.lang.System.exit(0)
  end

  test 'check_sum' do
    setup
    task = HL7Messaging.get_check_sum_task(subset: @subset_string, site_list: VaSite.all.to_a)
    HL7Messaging.start_checksum_task(task: task)
    result = HL7Messaging.fetch_result(task: task)
    p "check_sum test result is #{result}"
    #result = 'fizzle'
    assert(result.eql?('done'), 'Expected a result of done, received a result of ' + result.to_s)
    tear_down
  end
end
