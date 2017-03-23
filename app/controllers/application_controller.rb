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
  prepend_before_action :setup_time if self.respond_to? :setup_time
  prepend_before_action :add_pundit_methods
  after_action :verify_authorized, unless: :devise_controller?
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
    configured = true

    [PrismeService::NEXUS, PrismeService::JENKINS, PrismeService::TOMCAT, PrismeService::GIT].each do |svc|
      configured = false unless Service.service_exists? svc
    end

    render :file => (trinidad? ? 'public/not_configured.html' : "#{Rails.root}/../not_configured.html") unless configured
  end

  def validate_terminology_config
    return unless $terminology_parse_errors
    error_str = PrismeUtilities::terminology_config_errors.join("<br>")
    erb = (trinidad? ? 'public/terminology_config_error.html.erb' : "#{Rails.root}/../terminology_config_error.html.erb")
    erb_str = File.open(erb, 'r') { |file| file.read }
    erb_str = ERB.new(erb_str).result(binding)
    render html: erb_str.html_safe
    return

    # if exception.is_a?(Pundit::NotAuthorizedError) || exception.is_a?(Pundit::AuthorizationNotPerformedError)
    #   erb = "#{Rails.root}/lib/rails_common/public/not_authorized.html.erb"
    #   erb_str = File.open(erb, 'r') { |file| file.read }
    #   erb_str = ERB.new(erb_str).result(binding)
    #   render html: erb_str.html_safe
    # else
    #   raise exception
    # end
  end

  def add_pundit_methods
    NavigationPolicy.add_action_methods self
  end

end
