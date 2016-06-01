class RolesController < ApplicationController

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token
  force_ssl if: :ssl_configured_delegator? #,port: 8443


  def get_roles
    @user_id = params[:id]
    @password = params[:password]
    $log.debug("About to fetch the roles for ID #{@user_id}")
    @roles_array = []
    user = User.find_by(email: @user_id)
    @authenticated = false
    @authenticated = user.valid_password?(@password) unless user.nil?
    $log.info("The user #{@user_id} tried to get roles but was not authenticated.") unless @authenticated
    unless (user.nil? || !@authenticated)
      user.roles.each do |role|
        @roles_array << role
      end
    end
    respond_to do |format|
      format.html # get_roles.html.erb
      format.json { render :json => @roles_array }
    end
  end

  private

  def ssl_configured_delegator?
    RolesController.ssl_configured?
  end

  def self.ssl_configured?
    false
    #!Rails.env.development?
  end

end
