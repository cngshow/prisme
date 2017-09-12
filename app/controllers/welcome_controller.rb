class WelcomeController < ApplicationController
  include TomcatConcern
  before_action :any_administrator, only: [:tomcat_app_action]
  before_action :ensure_services_configured
  skip_after_action :verify_authorized, :index, :reload_job_queue_list

  def index
    # get tomcat deployments
    tomcat_deployments = tomcat_server_deployments
    @deployments = format_deployments_table_data(tomcat_deployments)
  end

  def session_timeout
    redirect_to ssoi? ? roles_sso_logout_path : destroy_user_session_path
  end

  def tomcat_app_action
    tomcat_service_id = params[:tomcat_service_id]
    tomcat_app = params[:tomcat_app]
    tomcat_action = params[:tomcat_action]
    uuid = params[:war_uuid]
    # get the Service name for displaying in the flash
    service = Service.find(tomcat_service_id)
    service_name = service.name

    # call TomcatConcern to perform the specified action
    flash_state = change_state(tomcat_service_id: tomcat_service_id, context: tomcat_app, action: tomcat_action)
    flash_state << " on #{service_name}"
    flash_notify(message: flash_state)
    if (@change_state_succeded)
      $log.info("Updating the model for uuid #{uuid} to have state #{tomcat_action}") if uuid
      UuidProp.uuid(uuid: uuid, state: tomcat_action)
    end
    reload_deployments
  end

  def check_isaac_dependency
    war_uuid = params[:war_uuid]
    unless war_uuid
      render json: {dependency: false}
      return
    end
    prop = UuidProp.uuid(uuid: war_uuid)
    dependency = prop.running_dependency?
    if dependency #either false or a string containing the name of the dependent
      render json: {dependency: true, name: dependency}
    else
      render json: {dependency: false, name: dependency}
    end
  end

  def reload_job_queue_list
    row_limit = params['row_limit'] ||= 15
    json = JSON.parse PrismeJob.job_name('PrismeCleanupJob', true).order(scheduled_at: :desc).limit(row_limit).to_json

    json.each do |j|
      if !j['started_at'].nil? && !j['completed_at'].nil?
        j[:elapsed_time] = ApplicationHelper.convert_seconds_to_time(Time.parse(j['completed_at']) - Time.parse(j['started_at']))
      else
        j[:elapsed_time] = 'N/A'
      end
    end
    render json: json
  end

  def rename_war
    ret = {status: 'failure'}
    uuid = params[:uuid]
    war_name = params[:war_name]
    war_descr = params[:war_description] #war_description
    prop = UuidProp.uuid(uuid: uuid)
    if prop
      ret = {status: 'success'} if prop.save_json_hash(UuidProp::Keys::NAME => war_name, UuidProp::Keys::DESCRIPTION => war_descr)
    end
    render json: ret
  end

  def reload_log_events
    row_limit = (params['row_limit'] ||= 15).to_i
    results_fatal = []
    results_error = []
    results_low_level = []
    LogEvent.all.order(created_at: :desc).each do |record|
      if record.level.eql?(PrismeLogEvent::LEVELS[:FATAL]) && record.acknowledged_by.nil?
        results_fatal << record
      elsif record.level.eql?(PrismeLogEvent::LEVELS[:ERROR]) && record.acknowledged_by.nil?
        results_error << record
      else
        results_low_level << record
      end
    end
    results = results_fatal + results_error + results_low_level
    results = results[0...row_limit] unless results.length < row_limit
    render json: results.to_json
  end

  def reload_deployments
    # reload the deployments
    index

    # render the deployments partial
    render partial: 'welcome/deployments'
  end

  private
  def format_deployments_table_data(tomcat_deployments)
    is_admin_user = any_administrator?
    ret = []
    tomcat_deployments.keys.each do |appserver|
      service_name = appserver[:service_name]
      service_desc = appserver[:service_desc]
      current_row = {service_id: appserver[:service_id], service_name: service_name, service_desc: service_desc, available: false, rows: []}

      # get all of the applications deployed at this app server location
      tomcat_deployments[appserver].each_pair do |war, d|
        $log.trace("APPSERVER is #{appserver.inspect}")
        $log.trace("war is #{war.inspect}")
        $log.trace("D is #{d.inspect}")
        current_row[:available] = true #this line toggles between the no apps on tomcat vs tomcat is unavailable or mis-configured message.  It must be first
        next if [:available, :failed].include?(war) #This line ensures we skip over Tomcats that have no applications installed or that aren't responding properly.  It must be second!
        war_uuid = tomcat_deployments[appserver][war][:war_id]
        hash = {war_uuid: war_uuid}.merge(uuid_hash(uuid: war_uuid))

        if war =~ /komet/
          isaac_war_uuid = d[:isaac][:war_id] if d[:isaac]
          hash[:isaac_war_uuid] = isaac_war_uuid
          hash[:isaac_war_name] = uuid_name(uuid: isaac_war_uuid)
        end

        if is_admin_user || war =~ /komet/
          war_name = war =~ /komet/ ? "Term Editor #{war.last.upcase}" : war
          link = ssoi? ? URI(d[:link]).proxify.to_s : d[:link]
          hash.merge!({war_label: war_name, war_name: war, state: d[:state], version: d[:version], session_count: d[:session_count].to_s, link: link})
          hash[:isaac] = d[:isaac] if d[:isaac]
          hash[:komets_isaac_version] = d[:komets_isaac_version] if d[:komets_isaac_version]
          current_row[:rows] << HashWithIndifferentAccess.new(hash)
        end
      end
      ret << current_row
    end
    ret
  end

  private

  def uuid_name(uuid:)
    return '' if uuid.to_s.empty?
    prop = UuidProp.uuid(uuid: uuid)
    prop.get(key: UuidProp::Keys::NAME).to_s
  end

  def uuid_hash(uuid:)
    return {} if uuid.to_s.empty?
    record = UuidProp.uuid(uuid: uuid)
    h = HashWithIndifferentAccess.new
    UuidProp::Keys.constants.each do |k|
      h[UuidProp::Keys.const_get(k)] = record.get(key: UuidProp::Keys.const_get(k))
    end
    h
  end
end
