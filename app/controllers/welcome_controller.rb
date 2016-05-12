require 'uri'

class WelcomeController < ApplicationController
  include TomcatConcern

  before_action :ensure_services_configured, except: [:toggle_admin]
  skip_after_action :verify_authorized, :index

  def index
    $log.debug(current_user.email) unless current_user.nil?
    $log.debug(current_user.to_s) if current_user.nil?

    # retrieve tomcat services
    tomcats = Service.get_application_servers
    tomcat_deployments = {}

    # iterate and make faraday call to get the text/list
    tomcats.each do |tomcat|
      # get the properties hash for the tomcat service
      service_props = tomcat.properties_hash
      url = service_props[PrismeService::CARGO_REMOTE_URL]
      username = service_props[PrismeService::CARGO_REMOTE_USERNAME]
      password = service_props[PrismeService::CARGO_REMOTE_PASSWORD]
      data_hash = nil

      begin
        data_hash = get_deployments(url: url, username: username, pwd: password)
        tomcat_deployments[{url: url, service_name: tomcat.name}] = data_hash
        @deployments = format_deployments_table_data(tomcat_deployments)
      rescue
      end
      $log.debug("tomcat_deployments are #{@deployments}")
    end
  end

  #delete this before single sign on
  def toggle_admin
    User.all.each do |u|
      $log.debug("Admin for #{u.email} is #{u.administrator}")
      u.administrator = !u.administrator
      $log.debug("Setting admin for #{u.email} to #{u.administrator}")
      saved = u.save!
      $log.debug("Admin state saved is #{saved}.")
    end
    redirect_to root_path
  end

  private
  def format_deployments_table_data(tomcat_deployments)
    ret = []

    tomcat_deployments.keys.each do |appserver|
      url = appserver[:url]
      uri = URI.parse(url)
      scheme = uri.scheme
      host = uri.host
      port = uri.port
      link = "#{scheme}://#{host}:#{port}"
      service_name = appserver[:service_name]
      current_row = {service_name: service_name, available: false, rows: []}

      # get all of the applications deployed at this appserver location
      tomcat_deployments[appserver].each_pair do |war, d|
        current_row[:available] = true
        next if war.eql? :failed
        row_click_url = link.clone << d[:context]
        war_name = war
        # filter to only display isaac and rails war files
        next unless war =~ /^(isaac|rails).*/
        state = d[:state]
        session_count = d[:session_count].to_s
        current_row[:rows] << {war_name: war_name, state: state, session_count: session_count, link: row_click_url}
      end
      ret << current_row
    end
    ret
  end
end
