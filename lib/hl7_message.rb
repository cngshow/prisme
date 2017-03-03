module JIsaacLibrary

  java_import 'gov.vha.isaac.ochre.deployment.hapi.extension.hl7.message.HL7Messaging' do |p, c|
    'JHL7Messaging'
  end

  #include_package 'gov.vha.isaac.ochre.deployment.hapi.extension.hl7.message' #HL7Messaging
  include_package 'gov.vha.isaac.ochre.access.maint.deployment.dto' #PublishMessageDTO, SiteDTO
  include_package 'gov.vha.isaac.ochre.services.dto.publish' #HL7ApplicationProperties

  module Task
    READY = javafx.concurrent.Worker::State::READY
    SCHEDULED = javafx.concurrent.Worker::State::SCHEDULED
    RUNNING = javafx.concurrent.Worker::State::RUNNING
    SUCCEEDED = javafx.concurrent.Worker::State::SUCCEEDED
    CANCELLED = javafx.concurrent.Worker::State::CANCELLED
    FAILED = javafx.concurrent.Worker::State::FAILED
    NOT_STARTED = :'NOT STARTED'

    def self.convert_string(s)
      s = s.to_s
      return NOT_STARTED if s.eql? NOT_STARTED.to_s
      javafx.concurrent.Worker::State.value_of(s) rescue nil
    end

  end
end

module HL7Messaging

  HL7_SERVER_CONFIG_YML = 'hl7/hl7_server_config.yml'
  DB_WRITER = Concurrent::FixedThreadPool.new($PROPS['PRISME.db_writer_thread_pool'].to_i)

  class << self
    #these leak state, you should use the the defined methods unless you know what you are doing...
    attr_accessor :hl7_server_config #hl7_server_config.yml
    attr_accessor :hl7_message_config #hl7_message_config.yml.erb
  end

  module ClassMethods

    #called in the initializer thread.
    def init_messaging_engine
      @@hl7_started ||= false
      return @@hl7_started if @@hl7_started #don't enable it twice
      @@application_properties ||= HL7Messaging::ApplicationProperties.new
      @@message_properties ||= HL7Messaging::MessageProperties.new
      $log.info("About to start the HL7 Engine.")
      begin
        $log.info("Setting application properties via enable listener")
        the_classloader_of_love = JIsaacLibrary::JHL7Messaging.java_class.to_java.getClassLoader
        java.lang.Thread.currentThread.setContextClassLoader(the_classloader_of_love)
        JIsaacLibrary::JHL7Messaging.enableListener(@@application_properties)
        @@hl7_started = true
      rescue => ex
        $log.fatal("I could not enable the listener for HL7 Messaging.  Please have an administrator take a long hard look at #{HL7Messaging::HL7_SERVER_CONFIG_YML}.")
        $log.fatal("Prisme will continue to come up...")
        $log.error(ex.message)
        $log.error(ex.backtrace.join("\n"))
        @@hl7_started = false #shouldn't get here
      end
      $log.info("HL7 Engine started.") if @@hl7_started
      return @@hl7_started
    end

    def running?
      JIsaacLibrary::JHL7Messaging.isRunning
    end


    # task = HL7Messaging.get_check_sum_task(check_sum: 'some_string', site_list: VaSite.all.to_a)
    def get_check_sum_task(checksum_detail_array:)
      raise IllegalStateError.new('Not initialized!!') unless defined? @@message_properties
      task = JIsaacLibrary::JHL7Messaging.checksum(checksum_detail_array, @@message_properties)
      begin
        $log.info("About to attempt a discovery with the same site list from your get_check_sum_task.  No listeners will be registered.  View the java logs....")
        clones = checksum_detail_array.map do |e| e.clone end
        clones.each do |d| d.double = true end
        JIsaacLibrary::JHL7Messaging.discovery(clones, @@message_properties)
      rescue => ex
        $log.error("Discovery failure" + Logging.trace(ex))
      end
      task
    end

    def get_discovery_task(discovery_detail_array:)
      raise IllegalStateError.new("Not initialized!!") unless defined? @@message_properties
      task = JIsaacLibrary::JHL7Messaging.discovery(discovery_detail_array, @@message_properties)
      task
    end

    # WARNING!! THIS is done for us now...
    # HL7Messaging.start_checksum_task(task: task)
    def start_hl7_task(task:)
      $log.info('Starting HL7 task')
      JIsaacLibrary::WorkExecutors.get().getExecutor().execute(task)
      $log.info('HL7 task started!')
    end


    #convenience method
    # HL7Messaging.fetch_result(task: task)
    def fetch_result(task:)
      JIsaacLibrary.fetch_result(task: task)
    end

    #see PrismeConstants::ENVIRONMENT for keys
    def server_environment
      return (HashWithIndifferentAccess.new HL7Messaging.hl7_server_config).deep_dup unless HL7Messaging.hl7_server_config.nil?
      HL7Messaging.hl7_server_config = PrismeUtilities.fetch_yml HL7_SERVER_CONFIG_YML
      (HashWithIndifferentAccess.new HL7Messaging.hl7_server_config).deep_dup
    end

    def message_environment
      return (HashWithIndifferentAccess.new HL7Messaging.hl7_message_config).deep_dup unless HL7Messaging.hl7_message_config.nil?
      HL7Messaging.hl7_message_config = PrismeUtilities.fetch_yml 'hl7/hl7_message_config.yml.erb'
      (HashWithIndifferentAccess.new HL7Messaging.hl7_message_config).deep_dup
    end

    #this method is called by the controller.
    #subset_hash looks like {'Allergy' => ['Reaction', 'Reactants'], 'Immunizations' => ['Immunization Procedure']}
    def build_checksum_task_active_record(user:, subset_hash:, site_ids_array:)
      # started = HL7Messaging.init_messaging_engine
      # $log.debug("Messaging engine started?: #{started}")
      task_ar_array = []
      site_ids = []
      cr_array = []
      site_ids_array.each do |site_id|
        site_ids << {va_site_id: site_id}
      end
      subset_hash.each_pair do |main_subset, subset_array|
        cr = ChecksumRequest.new
        cr.username = user
        cr.domain = main_subset
        subset_array.each do |subset|
          cd_array = cr.checksum_details.build site_ids
          cd_array.each do |cd|
            cd.subset = subset
            cd.status = JIsaacLibrary::Task::NOT_STARTED.to_s
          end
        end
        cr_array << cr
      end
      ChecksumRequest.transaction do
        cr_array.each(&:save!)
      end
      kick_off_checksums(cr_array)
      cr_array
    end

    private
    def kick_off_checksums(cr_array)
      cr_array.each do |checksum_request|
        #the call to 'to_a' (below) inflates the models.
        task_array = get_check_sum_task(checksum_detail_array: checksum_request.checksum_details.to_a)
        #the tasks in task array are all started!!
        task_to_detail_map = {}
        details = checksum_request.checksum_details.to_a
        task_array.zip(details) do |task, detail|
          task_to_detail_map[task] = detail
        end
        task_array.each do |task|
          runnable = -> do
            observer = HL7Messaging::HL7ChecksumObserver.new(task_to_detail_map[task], task)
            task.stateProperty.addListener(observer)
            observer.initial_state_check
          end # Register with the observable
          javafx.application.Platform.runLater(runnable)
        end
      end
    end

  end

  extend ClassMethods

  # p = HL7Messaging::ApplicationProperties.new
  class ApplicationProperties
    include gov.vha.isaac.ochre.services.dto.publish.ApplicationProperties
    include JavaImmutable

    attr_reader :server_environment

    def initialize
      @server_environment = HL7Messaging.server_environment[PRISME_ENVIRONMENT] # PRISME_ENVIRONMENT = dev, sqa, etc
      @server_environment.keys.each do |key|
        method_name = "get#{key.camelize_preserving}".to_sym
        self.define_singleton_method(method_name) do
          @server_environment[key]
        end
      end
    end

    def getApplicationServerName
      PRISME_ENVIRONMENT
    end

    def getApplicationVersion
      PRISME_VERSION
    end
  end

  # p = HL7Messaging::MessageProperties.new
  class MessageProperties
    include gov.vha.isaac.ochre.services.dto.publish.MessageProperties
    include JavaImmutable

    attr_reader :message_environment

    def initialize
      @message_environment = HL7Messaging.message_environment
      @message_environment.keys.each do |key|
        method_name = "get#{key.camelize_preserving}".to_sym
        self.define_singleton_method(method_name) do
          @message_environment[key]
        end
      end
    end
  end

  class HL7ChecksumObserver < JIsaacLibrary::TaskObserver
    include JIsaacLibrary::Task


    def initialize(checksum_detail, task)
      raise ArgumentError.new("Please pass in a " + ChecksumDetail.to_s + ".  I got a #{checksum_detail.inspect}") unless checksum_detail.is_a? ChecksumDetail
      @checksum_detail = checksum_detail
      @task = task
      @change_monitor = Monitor.new #monitors are re-entrant
    end

    #This method is called after construction and registration with the fx listener
    def initial_state_check
      @change_monitor.synchronize do
        state = @task.getState #runLater thread
        #com.sun.javafx.application.PlatformImpl.runAndWait(-> do state = @task.getState end) #if sun ever takes this away Dan will give us one!
        @checksum_detail.start_time = Time.now unless @checksum_detail.start_time #tasks are started when I get them
        changed(nil, nil, state)#making use of re-entrancy here...
      end
    end

    def changed(observable_task_property, old_value, new_value)
      name = java.lang.Thread.currentThread.getName
      puts "My thread name in changed is #{name}"
      @change_monitor.synchronize do
        super observable_task_property, old_value, new_value
        begin
          @old_value = old_value
          @new_value = new_value
          @checksum_detail.status = @new_value.to_s
          case @new_value
            when SUCCEEDED, FAILED, CANCELLED
              @checksum_detail.finish_time = Time.now unless @checksum_detail.finish_time
              if ([FAILED, CANCELLED].include?(@new_value))
                message_string = nil
                message_string = @task.getMessage
                #runnable = -> do message_string = @task.getMessage end #add this to active record display on each row. Only get for failed or cancelled
                #com.sun.javafx.application.PlatformImpl.runAndWait(runnable)
                @checksum_detail.failure_message = message_string
              end
              mock_checksum if Rails.env.development?
            when RUNNING
              @checksum_detail.start_time = Time.now unless @checksum_detail.start_time
            else
              #nothing
          end
        rescue => ex
          observing_error(ex)
          raise ex
        end
        $log.info("The checksum detail #{@checksum_detail.inspect} is now #{@new_value}!")
        cd_clone = @checksum_detail.clone
        DB_WRITER.post do
          $log.error("I failed to record the data #{@checksum_detail.inspect} to the database!") unless cd_clone.save
        end
      end
    end

    def mock_checksum
      file = Tempfile.new('checksum_simulator')
      file.write([*('a'..'z'), *('0'..'9')].shuffle[0, 36].join)
      file.close
      @checksum_detail.checksum = Digest::MD5.file(file).to_s
      #detail.discovery_data = DISCOVERY_MOCK
      file.unlink
    end
  end

  DISCOVERY_MOCK = %(
MSH^~|\&^XUMF DATA^442^VETS DATA^660INT^20060731124021-0400^^MFR~M01^44210935997^T^2.4^^^AL^NE^USA
MSA^AA^200607311040367311^
QRD^20060731104000.000-0600^R^I^Standard Terminology Query^^^99999^ALL^Vital Types^VA
MFI^Vital Types^Standard Terminology^MUP^20060731124021-0400^20060731124021-0400^NE
MFE^MUP^^20060731124021-0400^Vital Types@871299
ZRT^Term^HOLLI HEIGHT
ZRT^VistA_Short_Name^HH
ZRT^VistA_Type_Rate^YES
ZRT^VistA_Rate_Input_Transform^D EN3\F\GMRVUT0 K:X=0!(X>100)!(X<1) X
ZRT^VistA_Type_Rate_Help^GMRV-HEIGHT RATE HELP
ZRT^VistA_PCE_Abbreviation^
ZRT^Status^1
MFE^MUP^^20060731124021-0400^Vital Types@4688728
ZRT^Term^VISION UNCORRECTED
ZRT^VistA_Short_Name^VU
ZRT^VistA_Type_Rate^YES
ZRT^VistA_Rate_Input_Transform^K:'$$VALID\F\GMRVPCE3("VU",X) X
ZRT^VistA_Type_Rate_Help^
ZRT^VistA_PCE_Abbreviation^VU
ZRT^Status^1
).strip

end
=begin
p = HL7Messaging::MessageProperties.new
m = p.to_java
m.setVersionId("Development")
m.getVersionId
m.getQueryLimitedRequestUnits

=end
=begin
load('./lib/hl7_message.rb')

site = JIsaacLibrary::Site.new
pm = JIsaacLibrary::PublishMessageDTO.new(1,site)
hl7_string = 'MSH^~|\&^VETS MD5^660VM5^XUMF MD5^950^20160825095000.000-0600^^MFQ~M01^62209^T^2.4^^^AL^AL^USA QRD^20160825095000.000-0600^R^I^Standard Terminology Query^^^99999^ALL^Imm Procedures^VA'
task = HL7Messaging.get_check_sum_task(hl7_message_string: hl7_string, site_list: [pm])
HL7Messaging.start_checksum_task(task: task)
puts "The result is #{HL7Messaging.fetch_result(task)}"


sample hl7 message
MSH^~|\&^VETS MD5^660VM5^XUMF MD5^950^20160825095000.000-0600^^MFQ~M01^62209^T^2.4^^^AL^AL^USA QRD^20160825095000.000-0600^R^I^Standard Terminology Query^^^99999^ALL^Imm Procedures^VA

=end