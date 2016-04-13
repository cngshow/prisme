class WelcomeController < ApplicationController
  def index
    $log.debug(current_user.email) unless current_user.nil?
    $log.debug(current_user.to_s) if current_user.nil?
    #redirect_to destroy_user_session_path
  end
end
