class RolesController < ApplicationController

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token
  force_ssl if: :ssl_configured_delegator? #,port: 8443


  def get_roles
    @user_id = params[:id]
    $log.debug("About to fetch the roles for ID #{@user_id}")
    @roles_array = []
    user = User.find_by(email: @user_id)
    unless (user.nil?)
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
