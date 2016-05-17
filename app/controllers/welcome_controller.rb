require 'uri'

class WelcomeController < ApplicationController
  include TomcatConcern

  before_action :ensure_services_configured, except: [:toggle_admin]
  skip_after_action :verify_authorized, :index

  def index
    $log.debug(current_user.email) unless current_user.nil?
    $log.debug(current_user.to_s) if current_user.nil?

    # get tomcat deployments
    tomcat_deployments = tomcat_server_deployments
    @deployments = format_deployments_table_data(tomcat_deployments)
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
      service_name = appserver[:service_name]
      current_row = {service_name: service_name, available: false, rows: []}

      # get all of the applications deployed at this appserver location
      tomcat_deployments[appserver].each_pair do |war, d|
        current_row[:available] = true
        next if war.eql? :failed
        current_row[:rows] << {war_name: war, state: d[:state], session_count: d[:session_count].to_s, link: d[:link]}
      end
      ret << current_row
    end
    ret
  end
end
