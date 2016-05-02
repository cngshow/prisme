require './app/policies/navigation_policy'
require './lib/rails_common/util/controller_helpers'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit
  include CommonController

  after_action :verify_authorized, unless: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :setup_gon
  rescue_from Exception, :with => :internal_error

  def internal_error(e)
    $log.error(e.message)
    $log.error request.fullpath
    $log.error(e.backtrace.join("\n"))

    if (e.is_a?(Pundit::AuthorizationNotPerformedError) || e.is_a?(Pundit::NotAuthorizedError))
      redirect_to "#{root_path}not_authorized.html"
      return
    elsif e.is_a? Faraday::ConnectionFailed
      # thrown if Nexus is down.
      redirect_to "#{root_path}nexus_not_available.html"
      return
    end

    raise e
  end

  def setup_gon
    gon.job_status_constants = PrismeJobConstants::Status::STATUS_HASH.invert
    setup_routes
  end


  def auth_registered
    authorize :navigation, :registered?
  end

  def auth_admin
    authorize :navigation, :admin?
  end

  def ensure_services_configured
    artifactory_configured = Service.service_exists? PrismeService::NEXUS
    build_server_configured = Service.service_exists? PrismeService::JENKINS
    application_server_configured = Service.service_exists? PrismeService::TOMCAT
    redirect_to "#{root_path}not_configured.html" unless (application_server_configured && artifactory_configured  && build_server_configured)
    return
  end

end
