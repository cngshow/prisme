require './app/policies/navigation_policy'
require './lib/rails_common/util/controller_helpers'
require './lib/rails_common/roles/ssoi'
require './lib/rails_common/roles/user_session'
require './lib/rails_common/util/servlet_support'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit
  include CommonController
  include SSOI
  include ServletSupport
  include UserSession

  after_action :verify_authorized, unless: :devise_controller?
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :setup_gon, :read_ssoi_headers
  rescue_from Exception, :with => :internal_error
  rescue_from Pundit::NotAuthorizedError, Pundit::AuthorizationNotPerformedError, :with => :pundit_error

  attr_reader :ssoi # a boolean if we have ssoi headers
  alias ssoi? ssoi
  alias pundit_user prisme_user

  def internal_error(exception)
    $log.error(exception.message)
    $log.error(exception.class.to_s)
    $log.error request.fullpath
    $log.error(exception.backtrace.join("\n"))

    case exception
      when Faraday::ClientError
        render :file => (trinidad? ? 'public/nexus_not_available.html' : "#{Rails.root}/../nexus_not_available.html")
        return
      when JIsaacLibrary::GitFailureException
        render :file => (trinidad? ? 'public/git_not_available.html' : "#{Rails.root}/../git_not_available.html")
        return
      else
        raise exception
    end
  end

  def setup_gon
    gon.job_status_constants = PrismeJobConstants::Status::STATUS_HASH.invert
    setup_routes
  end

  def read_ssoi_headers
    ssoi_user_name = ssoi_headers
    @ssoi = !ssoi_user_name.to_s.strip.empty? #we are using ssoi
    unless ssoi?
      clear_ssoi_user
      return
    end

    user = SsoiUser.where(ssoi_user_name: ssoi_user_name).first_or_create
    user_session(UserSession::SSOI_USER, user)
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
    render :file => (trinidad? ? 'public/not_configured.html' : "#{Rails.root}/../not_configured.html") unless (application_server_configured && artifactory_configured && build_server_configured && git_server_configured)
  end
end
