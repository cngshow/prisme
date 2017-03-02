$testing = true
require 'test_helper'
require './config/initializers/01_prisme_init'

class Hl7MessagingTest < ActionDispatch::IntegrationTest

  def request_checksum(observing = false)
    @cr = ChecksumRequest.new
    @cr.username = 'Cris'
    @cr.domain = 'Allergy'
    subset = 'Reactants'
    site_ids = []
    ['443', '442'].each do |site_id|
      site_ids << {va_site_id: site_id}
    end
    cd_array = @cr.checksum_details.build site_ids
    cd_array.each do |cd|
      cd.subset = subset
      cd.status = JIsaacLibrary::Task::NOT_STARTED
    end
    @cr.save!
    task_array = HL7Messaging.get_check_sum_task(checksum_detail_array: @cr.checksum_details.to_a)
    task_to_detail_map = {}
    details = @cr.checksum_details.to_a
    # puts "Task array (#{task_array.length}) = #{task_array.toString}"
    # puts "details (#{details.length})= #{details.inspect}"
    task_array.zip(details) do |task, detail|
      task_to_detail_map[task] = detail
    end
    if observing
      task_array.each do |task|
        @observer = HL7Messaging::HL7ChecksumObserver.new(task_to_detail_map[task], task)
        runnable = -> do
          task.stateProperty.addListener(@observer)
          @observer.initial_state_check
        end
        javafx.application.Platform.runLater(runnable)
      end
    end
    #HL7Messaging.start_hl7_task(task: task)
    task_array.each do |task|
      HL7Messaging.fetch_result(task: task) #blocking call
    end
  end

  #
  # def request_discovery(observing = false)
  #   @cr = ChecksumRequest.new
  #   @cr.username = 'Cris'
  #   @cr.subset_group = 'Allergy'
  #   @cr.status = JIsaacLibrary::Task::NOT_STARTED
  #   subset = 'Reactants'
  #   site_ids = []
  #   ['443','442'].each do |site_id|
  #     site_ids << {va_site_id: site_id}
  #   end
  #   cd_array = @cr.checksum_details.build site_ids
  #   cd_array.each do |cd|
  #     cd.subset = subset
  #   end
  #   @cr.save!
  #   #the task array order aligns with the order of checksum details
  #   details = @cr.checksum_details.to_a
  #   task_array = HL7Messaging.get_discovery_task(discovery_detail_array: details)
  #   task_to_detail_map = {}
  #   task_array.zip(details) do |task,detail| task_to_detail_map[task] = detail
  #   if observing
  #     task_array.each do |task|
  #       @observer = HL7Messaging::HL7ChecksumObserver.new @cr
  #       task.stateProperty.addListener(@observer)
  #     end
  #   end
  #   HL7Messaging.start_hl7_task(task: task)
  #   HL7Messaging.fetch_result(task: task) #blocking call
  # end

  setup do
    @subset_string='some_string'
    PrismeUtilities.synch_site_data
    PrismeUtilities.synch_group_data
    @app_prop = HL7Messaging::ApplicationProperties.new.to_java
    started = HL7Messaging.init_messaging_engine
    raise "I couldn't initialize the HL7Messaging engine! #{started}" unless started
  end

  teardown do

  end

  # test 'discovery' do
  #   result = request_discovery
  #   if(result.is_a? java.lang.Exception)
  #     puts "#{result}"
  #     puts result.backtrace.join("\n")
  #   end
  #   #result = 'fizzle' #to force a failure
  #   assert(result.eql?('done'), 'Expected a result of done, received a result of ' + result.to_s)
  # end

  test 'check_sum' do
    result = request_checksum
    if (result.is_a? java.lang.Exception)
      puts "#{result}"
      puts result.backtrace.join("\n")
    end
    #result = 'fizzle' #to force a failure
    assert(result.eql?(nil), 'Expected a result of nil, received a result of ' + result.to_s)
  end

  test 'not_using_interface_engine' do
    use_interface_engine = @app_prop.getUseInterfaceEngine
    assert(use_interface_engine == false, "#{@app_prop.getApplicationServerName}: We should not be using the interface engine during test.  The value of use_interface_engine is #{use_interface_engine}")
  end


  test 'check_sum_observer' do
    name = java.lang.Thread.currentThread.getName
    puts "My thread name in test is #{name}"
    request_checksum(true)
    assert(@observer.new_value == JIsaacLibrary::Task::SUCCEEDED, "The final state of our checksum task was (between the arrows)-->#{@observer.new_value}<--, the old value is -->#{@observer.old_value}<--")
  end

  test 'application_property_url' do
    assert(@app_prop.getInterfaceEngineURL.is_a? String)
  end

  test 'message_id' do
    h = {'Allergy' => ['Reaction', 'Reactants'], 'Immunizations' => ['Immunization Procedure']}
    sites =["443", "444"]
    checksum_request = HL7Messaging.build_checksum_task_active_record(user: 'Cris', subset_hash: h, site_ids_array: sites)
    checksum_request.first.checksum_details.first.to_java.getMessageId
    assert(checksum_request.first.checksum_details.first.to_java.getMessageId.to_java.is_a?(java.lang.Long), "The message id is not a long")
  end

  test 'HL7_still_running' do
    running = HL7Messaging.running?
    assert(running, 'The HL7 engine is not running!!! (It should be)')
  end

end
