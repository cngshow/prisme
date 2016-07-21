class WelcomeController < ApplicationController
  include TomcatConcern
  before_action :auth_admin, only: [:tomcat_app_action]
  before_action :ensure_services_configured
  skip_after_action :verify_authorized, :index, :reload_job_queue_list

  def index
    $log.debug(current_user.email) unless current_user.nil?
    $log.debug(current_user.to_s) if current_user.nil?

    # get tomcat deployments
    tomcat_deployments = tomcat_server_deployments
    @deployments = format_deployments_table_data(tomcat_deployments)
  end
  
  def tomcat_app_action
    tomcat_service_id = params[:tomcat_service_id]
    tomcat_app = params[:tomcat_app]
    tomcat_action = params[:tomcat_action]

    # get the Service name for displaying in the flash
    service = Service.find(tomcat_service_id)
    service_name = service.name

    # call TomcatConcern to perform the specified action
    @flash_state = change_state(tomcat_service_id: tomcat_service_id, context: tomcat_app, action: tomcat_action)
    @flash_state = @flash_state.strip
    @flash_state << " on #{service_name}"
    ajax_flash(@flash_state, {type: 'success'})

    # reload the deployments
    index

    # render the deployments partial
    render partial: 'welcome/deployments'
  end

  def reload_job_queue_list
    row_limit = params['row_limit'] ||= 15
    json = JSON.parse PrismeJob.job_name('PrismeCleanupJob', true).order(scheduled_at: :desc).limit(row_limit).to_json

    json.each do |j|
      if (!j['started_at'].nil? && !j['completed_at'].nil?)
        j[:elapsed_time] = ApplicationHelper.convert_seconds_to_time(Time.parse(j['completed_at']) - Time.parse(j['started_at']))
      else
        j[:elapsed_time] = 'N/A'
      end
    end
    render json: json
  end

  def reload_deployments
    # reload the deployments
    index

    # render the deployments partial
    render partial: 'welcome/deployments'
  end

  private
  def format_deployments_table_data(tomcat_deployments)
    ret = []

    tomcat_deployments.keys.each do |appserver|
      service_name = appserver[:service_name]
      current_row = {service_id: appserver[:service_id], service_name: service_name, available: false, rows: []}

      # get all of the applications deployed at this appserver location
      tomcat_deployments[appserver].each_pair do |war, d|
        current_row[:available] = true
        next if [:available, :failed].include?(war)
        current_row[:rows] << {war_name: war, state: d[:state], version: d[:version], session_count: d[:session_count].to_s, link: d[:link]}
      end
      ret << current_row
    end
    ret
  end
end
