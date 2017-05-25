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
  # use_growlyflash

  append_view_path 'lib/rails_common/views'
  prepend_before_action :setup_time, :only => :time_stats #found in utility_controller
  prepend_before_action :add_pundit_methods
  after_action :verify_authorized, unless: :devise_controller?
  after_action :log_user_activity, unless: :devise_controller?
  before_action :verify_local_login, if: :devise_controller?
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :validate_terminology_config, :setup_gon, :read_ssoi_headers
  rescue_from Exception, java.lang.Throwable, :with => :internal_error
  rescue_from Pundit::NotAuthorizedError, Pundit::AuthorizationNotPerformedError, :with => :pundit_error

  alias pundit_user prisme_user

  def internal_error(exception)
    $log.error(exception.message)
    $log.error(exception.class.to_s)
    $log.error request.fullpath
    $log.error(exception.backtrace.join("\n"))

    case exception
      when Faraday::ClientError
        redirect_to nexus_not_available_path
        return
      when JIsaacLibrary::GitFailureException
        redirect_to git_not_available_path
        return
      else
        raise exception
    end
  end

  def setup_gon
    gon.job_status_constants = PrismeJobConstants::Status::STATUS_HASH.invert
    gon.log_event_level_constants = LogEvent::LEVELS
    gon.log_event_level_constants_inverted = LogEvent::LEVELS.invert
    gon.last_round_trip = Time.now.to_i
    gon.start_countdown_in = $PROPS['SSOI_TIMEOUT.start_countdown_in']
    gon.countdown_mins = $PROPS['SSOI_TIMEOUT.countdown_mins']
    setup_routes
  end

  def read_ssoi_headers
    ssoi_user_name = ssoi_headers
    unless ssoi_user_name.to_s.strip.empty?
      ssoi_user_name.to_sym.to_java.synchronized do
        SsoiUser.where(ssoi_user_name: ssoi_user_name).first_or_create
      end
      user_session(UserSession::SSOI_USER, ssoi_user_name)
    end
  end

  def ensure_services_configured
    unless defined? @@configured
      configured = true

      [PrismeService::NEXUS, PrismeService::JENKINS, PrismeService::TOMCAT, PrismeService::GIT].each do |svc|
        configured = false unless Service.service_exists? svc
      end

      if configured
        @@configured = true
      else
        redirect_to not_configured_path
      end
    end
  end

  def validate_terminology_config
    return unless $terminology_parse_errors
    error_str = PrismeUtilities::terminology_config_errors.join('<br>')
    render terminology_config_error_path, locals: {error_str: error_str}
  end

  def add_pundit_methods
    NavigationPolicy.add_action_methods self
  end

  def verify_local_login
     u = request.url
     return if (u.eql?(user_session_url) || u.eql?(new_user_session_url) || u.eql?(destroy_user_session_url))#you can login, you can logout.  That is it...
    NavigationPolicy.allow_local_signup self
  end
end
