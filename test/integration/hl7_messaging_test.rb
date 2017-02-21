$testing = true
require 'test_helper'
require './config/initializers/01_prisme_init'

class Hl7MessagingTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  def request_checksum(observing = false)
    @cr = ChecksumRequest.new
    @cr.username = 'Cris'
    @cr.subset_group = 'Allergy'
    @cr.status = JIsaacLibrary::Task::NOT_STARTED
    subset = 'Reactants'
    site_ids = []
    ['443','442'].each do |site_id|
      site_ids << {va_site_id: site_id}
    end
    cd_array = @cr.checksum_details.build site_ids
    cd_array.each do |cd|
      cd.subset = subset
    end
    @cr.save!
    task = HL7Messaging.get_check_sum_task(checksum_detail_array: @cr.checksum_details.to_a)
    if observing
      @observer = HL7Messaging::HL7ChecksumObserver.new @cr
      task.stateProperty.addListener(@observer)
    end
    HL7Messaging.start_hl7_task(task: task)
    HL7Messaging.fetch_result(task: task) #blocking call
  end

  def request_discovery(observing = false)
    @cr = ChecksumRequest.new
    @cr.username = 'Cris'
    @cr.subset_group = 'Allergy'
    @cr.status = JIsaacLibrary::Task::NOT_STARTED
    subset = 'Reactants'
    site_ids = []
    ['443','442'].each do |site_id|
      site_ids << {va_site_id: site_id}
    end
    cd_array = @cr.checksum_details.build site_ids
    cd_array.each do |cd|
      cd.subset = subset
    end
    @cr.save!
    task = HL7Messaging.get_discovery_task(discovery_detail_array: @cr.checksum_details.to_a)
    if observing
      @observer = HL7Messaging::HL7ChecksumObserver.new @cr
      task.stateProperty.addListener(@observer)
    end
    HL7Messaging.start_hl7_task(task: task)
    HL7Messaging.fetch_result(task: task) #blocking call
  end

  setup do
    @subset_string='some_string'
    PrismeUtilities.synch_site_data
    PrismeUtilities.synch_group_data
  end

  teardown do

  end

  test 'discovery' do
    result = request_discovery
    if(result.is_a? java.lang.Exception)
      puts "#{result}"
      puts result.backtrace.join("\n")
    end
    #result = 'fizzle' #to force a failure
    assert(result.eql?('done'), 'Expected a result of done, received a result of ' + result.to_s)
  end

  test 'check_sum' do
    result = request_checksum
    if(result.is_a? java.lang.Exception)
      puts "#{result}"
      puts result.backtrace.join("\n")
    end
    #result = 'fizzle' #to force a failure
    assert(result.eql?('done'), 'Expected a result of done, received a result of ' + result.to_s)
  end

  test 'not_using_interface_engine' do
    props = HL7Messaging::ApplicationProperties.new.to_java
    p 'Application props is ---------------------' + props.getApplicationServerName
    p props.inspect
    p ' ---------------------'
    use_interface_engine = props.getUseInterfaceEngine
    assert(use_interface_engine == false, "#{props.getApplicationServerName}: We should not be using the interface engine during test.  The value of use_interface_engine is #{use_interface_engine}")
  end


  test 'check_sum_observer' do
    request_checksum(true)
    assert(@observer.new_value == JIsaacLibrary::Task::SUCCEEDED,"The final state of our checksum task was (between the arrows)-->#{@observer.new_value}<--, the old value is -->#{@observer.old_value}<--")
  end

  test 'application_property_url' do
    app_prop = HL7Messaging::ApplicationProperties.new.to_java
    assert(app_prop.getInterfaceEngineURL.is_a? String)
  end

  test 'message_id' do
    h = {'Allergy' => ['Reaction', 'Reactants'], 'Immunizations' => ['Immunization Procedure']}
    sites =["443", "444"]
    checksum_request = HL7Messaging.build_checksum_task_active_record(user: 'Cris', subset_hash: h, site_ids_array: sites)
    checksum_request.first.checksum_details.first.to_java.getMessageId
    assert(checksum_request.first.checksum_details.first.to_java.getMessageId.to_java.is_a?(java.lang.Long), "The message id is not a long")
  end
end
