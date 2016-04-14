class WelcomeController < ApplicationController

  skip_after_action :verify_authorized, :index

  def index
    $log.debug(current_user.email) unless current_user.nil?
    $log.debug(current_user.to_s) if current_user.nil?
  end
end
