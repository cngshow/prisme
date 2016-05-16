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

  def internal_error(exception)
    $log.error(exception.message)
    $log.error request.fullpath
    $log.error(exception.backtrace.join("\n"))
    @centered_flash = true

    case exception
      when Pundit::AuthorizationNotPerformedError
      when Pundit::NotAuthorizedError
        render :file => (trinidad? ? 'public/not_authorized.html' : "#{Rails.root}/../not_authorized.html")
        return
      when Faraday::ConnectionFailed
        render :file => (trinidad? ? 'public/nexus_not_available.html' : "#{Rails.root}/../nexus_not_available.html")
        return
      when JIsaacGit::GitFailureException
        render :file => (trinidad? ? 'public/git_not_available.html' : "#{Rails.root}/../git_not_available.html")
        return
    end
    raise exception
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
    git_server_configured = Service.service_exists? PrismeService::GIT
    @centered_flash = true
    render :file => (trinidad? ? 'public/not_configured.html' : "#{Rails.root}/../not_configured.html") unless (application_server_configured && artifactory_configured && build_server_configured && git_server_configured)
    return
  end
end
