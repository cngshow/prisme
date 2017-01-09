class LogEventsController < ApplicationController
  before_action :auth_admin, except: [:log_event]
  before_action :set_log_event, only: [:destroy, :acknowledge_log_event]
  skip_after_action :verify_authorized, only: [:log_event]
  skip_before_action :verify_authenticity_token, only: [:log_event]

  #http://localhost:3000/log_event?application_name=isaac&level=1&tag=SOME_TAG&message=broken&security_token=%5B%22u%5Cf%5Cx92%5CxBC%5Cx17%7D%5CxD1%5CxE4%5CxFB%5CxE5%5Cx99%5CxA3%5C%22%5CxE8%5C%5CK%22%2C+%22%3E%5Cx16%5CxDE%5CxA8v%5Cx14%5CxFF%5CxD2%5CxC6%5CxDD%5CxAD%5Cx9F%5Cx1D%5CxD1cF%22%5D
  def log_event
    puts params.inspect
    puts '----------------------'
    puts request.body.read
    puts '----------------------'
    log_event = LogEvent.new(log_event_create_params)
    log_event.hostname = true_address

    if log_event.save & valid_security_token? # do not short circuit
      $log.info('saved a log event to the database')
      render json: {event_logged: true}
    else
      failed_hash = {event_logged: false, validation_errors: log_event.errors}
      failed_hash[:token_error] = @token_error unless @token_error.nil?
      $log.warn("Failed to save log event #{log_event} to the database, #{failed_hash}")
      render json: failed_hash
    end
  end

  # this method is called from the gui via an ajax get to update and acknowledge the log event
  def acknowledge_log_event
    ret = {status: 'failure', message: 'Invalid log event id passed to acknowledge_event method.'}

    if @log_event
      @log_event.acknowledged_by = prisme_user.user_name
      @log_event.acknowledged_on = Time.now
      comment = params[:ack_comment] ||= ''
      comment.gsub!("\n", '<br>')
      @log_event.ack_comment = comment

      if @log_event.save

        # flash_notify ?!
        ret = {status: 'success', message: 'Log Event was successfully acknowledged!'}
      else
        ret = {status: 'failure', message: 'An error occurred while attempting to acknowledge a log event.'}
      end
    end
    render json: ret
  end

  # DELETE /log_events/1
  # DELETE /log_events/1.json
  def destroy
    @log_event.destroy
    respond_to do |format|
      format.html { redirect_to log_events_url, notice: 'Log event was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_log_event
      @log_event = LogEvent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def log_event_create_params
      hash = params.permit(:application_name, :level, :tag, :message, :security_token)
      hash.delete(:security_token) # this prevents the annoying 'Unpermitted parameter: security_token'
      hash
    end

  # Never trust parameters from the scary internet, only allow the white list through.
  def log_event_update_params
    params.permit(:acknowledged_by, :acknowledged_on, :ack_comment)
  end

  def valid_security_token?
    token = params[:security_token]
    valid = CipherSupport.instance.valid_security_token?(token: token)
    @token_error = "Invalid security token!" unless valid
    valid
  end

end