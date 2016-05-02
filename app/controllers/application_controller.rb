require './app/policies/navigation_policy'

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pundit
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
      render :file => 'public/not_authorized.html'
      return
    elsif e.is_a? Faraday::ConnectionFailed
      # thrown if Nexus is down.
      render :file => 'public/nexus_not_available.html'
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

  private
  def setup_routes
    routes = Rails.application.routes.named_routes.helpers.to_a
    @@routes_hash ||= {}
    if(@@routes_hash.empty?)
      routes.each do |route|
        begin
          @@routes_hash[route.to_s] = self.send(route)
        rescue ActionController::UrlGenerationError => ex
          if (ex.message =~ /missing required keys: \[(.*?)\]/)
            keys = $1
            keys = keys.split(',')
            keys.map! do |e|
              e.gsub!(':', '')
              e.strip
            end
            required_keys_hash = {}
            keys.each do |key|
              required_keys_hash[key.to_sym] = ':' + key.to_s
            end
            @@routes_hash[route.to_s] = self.send(route, required_keys_hash)
          else
            raise ex
          end
        end
      end
    end
    $log.debug('routes hash passed to javascript is ' + @@routes_hash.to_s)
    gon.routes = @@routes_hash
  end

end
