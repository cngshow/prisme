$testing = true
require 'test_helper'
require './config/initializers/01_prisme_init'

class Hl7MessagingTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  def request_checksum
    task = HL7Messaging.get_check_sum_task(subset: @subset_string, site_list: VaSite.all.to_a)
    task.stateProperty.addListener(@observer) unless @observer.nil?
    HL7Messaging.start_checksum_task(task: task)
    HL7Messaging.fetch_result(task: task) #blocking call
  end

  setup do
    @subset_string='some_string'
    PrismeUtilities.synch_site_data
    PrismeUtilities.synch_group_data
  end

  teardown do

  end

  test 'check_sum' do
    result = request_checksum
    p "check_sum test result is #{result}"
    #result = 'fizzle' #to force a failure
    assert(result.eql?('done'), 'Expected a result of done, received a result of ' + result.to_s)
  end


  test 'check_sum_observer' do
    @observer = HL7Messaging::HL7CheckSumObserver.new
    p 'checksum result is ' + request_checksum.to_s
    assert(@observer.new_value == JIsaacLibrary::Task::SUCCEEDED,"The final state of our checksum task was (between the arrows)-->#{@observer.new_value}<--, the old value is -->#{@observer.old_value}<--")
  end

  test 'application_property_url' do
    app_prop = HL7Messaging::ApplicationProperties.new.to_java
    assert(app_prop.getInterfaceEngineURL.is_a? String)
  end
end
