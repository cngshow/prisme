$testing = true
require 'test_helper'
require './config/initializers/01_prisme_init'


class Hl7MessagingTest < ActionDispatch::IntegrationTest

  def setup_test_user
    @user = User.new
    @user.email = 'test@tester.com'
    @user.password = @user.email
    @user.add_role(Roles::SUPER_USER)
    @user.save
  end

  def request(klass, observing = false, hl7_method, keyword)
    @record = klass.send(:new)
    @record.username = 'Cris'
    @record.domain = 'Allergy'
    subset = 'Reactants'
    site_ids = []
    ['613', '442'].each do |site_id|
      site_ids << {va_site_id: site_id}
    end
    cd_array = @record.details.build site_ids
    cd_array.each do |cd|
      cd.subset = subset
      cd.status = JIsaacLibrary::Task::NOT_STARTED
    end
    @record.save!
    task_array = HL7Messaging.send(hl7_method, {keyword => @record.details.to_a})
    task_to_detail_map = {}
    details = @record.details.to_a
    # puts "Task array (#{task_array.length}) = #{task_array.toString}"
    # puts "details (#{details.length})= #{details.inspect}"
    task_array.zip(details) do |task, detail|
      task_to_detail_map[task] = detail
    end
    if observing
      task_array.each do |task|
        @observer = HL7Messaging::HL7ChecksumDiscoveryObserver.new(task_to_detail_map[task], task)
        runnable = -> do
          task.stateProperty.addListener(@observer)
          @observer.initial_state_check
        end
        javafx.application.Platform.runLater(runnable)
      end
    end
    #HL7Messaging.start_hl7_task(task: task)
    results = []
    task_array.each do |task|
      results << HL7Messaging.fetch_result(task: task) #blocking call
    end
    results.reject do |e| e.nil? end
  end

  def request_checksum(observing = false)
    request(ChecksumRequest, observing, :get_check_sum_task, :checksum_detail_array)
  end

  def request_discovery(observing = false)
    request(DiscoveryRequest, observing, :get_discovery_task, :discovery_detail_array)
  end

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


  test 'check_sum' do
    result = request_checksum
    if (result.is_a? java.lang.Exception)
      puts "#{result}"
      puts result.backtrace.join("\n")
    end
    #result = 'fizzle' #to force a failure
    assert(result.length == 2, "Expected two results for two sites and one subest.  Received #{result.length}")
    result.each do |r|
      assert((result.to_s =~ /no response/i), "Expected no response, got #{result}")
    end
  end

  test 'discovery' do
    result = request_discovery
    if (result.is_a? java.lang.Exception)
      puts "#{result}"
      puts result.backtrace.join("\n")
    end
    #result = 'fizzle' #to force a failure
    assert(result.length == 2, "Expected two results for two sites and one subest.  Received #{result.length}")
    result.each do |r|
      assert((result.to_s =~ /no response/i), "Expected no response, got #{result}")
    end  end

  test 'not_using_interface_engine' do
    use_interface_engine = @app_prop.getUseInterfaceEngine
    assert(use_interface_engine == false, "#{@app_prop.getApplicationServerName}: We should not be using the interface engine during test.  The value of use_interface_engine is #{use_interface_engine}")
  end


  test 'check_sum_observer' do
    request_checksum(true)
    #we will have a failure as there is no response during the build
    assert(@observer.new_value == JIsaacLibrary::Task::FAILED, "The final state of our checksum task was (between the arrows)-->#{@observer.new_value}<--, the old value is -->#{@observer.old_value}<--")
  end

  test 'check_discovery_observer' do
    request_discovery(true)
    #we will have a failure as there is no response during the build
    assert(@observer.new_value == JIsaacLibrary::Task::FAILED, "The final state of our checksum task was (between the arrows)-->#{@observer.new_value}<--, the old value is -->#{@observer.old_value}<--")
  end

  test 'application_property_url' do
    assert(@app_prop.getInterfaceEngineURL.is_a? String)
  end

  test 'message_id' do
    h = {'Allergy' => ['Reaction', 'Reactants'], 'Immunizations' => ['Immunization Procedure']}
    sites =["613", "657"]
    checksum_request = HL7Messaging.build_checksum_discovery_ar(nav_type: 'checksum', user: 'Cris', subset_hash: h, site_ids_array: sites)
    checksum_request.first.checksum_details.first.to_java.getMessageId
    assert(checksum_request.first.checksum_details.first.to_java.getMessageId.to_java.is_a?(java.lang.Long), "The message id is not a long")
  end

  test 'HL7_still_running' do
    running = HL7Messaging.running?
    assert(running, 'The HL7 engine is not running!!! (It should be)')
  end

  #todo Greg fix.
  #Controller test cases
  test 'can_request_checksum' do
    now = Time.now
    setup_test_user
    domains = %q([{"id":"Allergy","text":"Allergy","subsets":[{"id":"j2_3","text":"Reactions","icon":true,"li_attr":{"id":"j2_3"},"a_attr":{"href":"#","id":"j2_3_anchor"},"state":{"loaded":true,"opened":false,"selected":true,"disabled":false},"data":{},"parent":"Allergy"}]}])
    sites = %q([{"id":950,"text":"STLVETSDEV"}])
    post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.email
    post hl7_messaging_results_table_path, nav_type: 'checksum', subset_selections: domains, site_selections: sites
    requests = ChecksumRequest.where('created_at > ?', now).to_a
    assert(requests.length == 1, "Too many checksum requests were found!  Expected 1, got #{requests.length}")
    assert(requests.first.checksum_details.length == 1, "Too many checksum details were found!  Expected 1, got #{requests.first.checksum_details.length}")
  end

end
