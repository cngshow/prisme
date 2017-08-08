class LogEventsController < ApplicationController

  resource_description do
    short 'Log Event APIs'
    formats ['json']
  end

  LOG_EVENT_PREAMBLE = :log_event_

  before_action :any_administrator, except: [:log_event]
  before_action :set_log_event, only: [:destroy, :acknowledge_log_event]
  skip_after_action :verify_authorized, only: [:log_event]
  skip_after_action :log_user_activity
  skip_before_action :verify_authenticity_token, only: [:log_event]

  # http://localhost:3000/log_event?application_name=isaac&level=1&tag=SOME_TAG&message=broken&security_token=%5B%225-t6%5Cx9D%3D%5Cf7%40z%5CxB5%5CxA1%5CxD1%2A%5CxDAT%22%2C+%22w67%5C%22%5CxFCT%5C%22%5Cx01%7DB%5Cx80%5Cx98%5CxE5%5Cx14%5CxE3Y%22%5D
  #  api :GET, PrismeUtilities::RouteHelper.route(:log_event_path), 'Submit a log event to Prisme\'s log event database'
  api :PUT, PrismeUtilities::RouteHelper.route(:log_event_path), 'Submit a log event to Prisme\'s log event database'
  api :POST, PrismeUtilities::RouteHelper.route(:log_event_path), 'Submit a log event to Prisme\'s log event database'
  param :application_name, String, desc: 'The name of the submitting application', required: true
  param :level, String, desc: "The log level.  The only valid levels are: #{PrismeLogEvent::LEVELS.values}, such that #{PrismeLogEvent::LEVELS.invert}.  As we support \'get\' requests the appropriate string representation is accepted.", required: true
  param :tag, String, desc: "A grouping tag intended to identify the type of event.", required: true
  param :message, String, desc: "The message to log.", required: true
  param :security_token, String, desc: "The security token given to your application.", required: true
  description %q{
Submits a log event to Prisme.

On success returns the following json:<br>
{"event_logged":true}<br>

On validation failure returns something like:<br>
{"event_logged":false,"validation_errors":{"level_error":["Invalid level. The level must be an integer corresponding to [[:ALWAYS, \"1\"], [:WARN, \"2\"], [:ERROR, \"3\"], [:FATAL, \"4\"]]"]}}<br>
On token error returns:<br>
{"event_logged":false,"validation_errors":{},"token_error":"Invalid security token!"}
  }
  def log_event
    log_event = LogEvent.new(log_event_create_params)
    log_event.hostname = true_address

    if valid_security_token?
      if log_event.save
        $log.info('saved a log event to the database')
        render json: {event_logged: true}
      else
        render json: {event_logged: false, validation_errors: log_event.errors}
      end
    else
      failed_hash = {event_logged: false, validation_errors: log_event.errors}
      failed_hash[:token_error] = @token_error unless @token_error.nil?
      $log.warn("Failed to save log event #{log_event} to the database, #{failed_hash}")
      render json: failed_hash
    end
  end

  # this method is called from the gui via an ajax get to update and acknowledge the log event
  def acknowledge_log_event
    if @log_event
      @log_event.acknowledged_by = prisme_user.user_name
      @log_event.acknowledged_on = Time.now
      comment = params[:ack_comment] ||= ''
      comment.gsub!("\n", '<br>')
      @log_event.ack_comment = comment

      if @log_event.save
        flash_notify(message: 'Log Event was successfully acknowledged!')
      else
        flash_alert(message: 'An error occurred while attempting to acknowledge a log event.')
      end
    else
      flash_alert(message: 'Invalid log event id passed to acknowledge_event method.')
    end
    render json: {}
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

  def react_log_events
    row_limit = (params['row_limit'] ||= 15).to_i
    results_fatal = []
    results_error = []
    results_low_level = []
    LogEvent.all.order(created_at: :desc).each do |record|
      if record.level.eql?(PrismeLogEvent::LEVELS[:FATAL]) && record.acknowledged_by.nil?
        results_fatal << record
      elsif record.level.eql?(PrismeLogEvent::LEVELS[:ERROR]) && record.acknowledged_by.nil?
        results_error << record
      else
        results_low_level << record
      end
    end
    results = results_fatal + results_error + results_low_level
    results = results[0...row_limit] unless results.length < row_limit
    render json: results.to_json
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
    valid = TokenSupport.instance.valid_security_token?(token: token, preamble: LOG_EVENT_PREAMBLE)
    @token_error = 'Invalid security token!' unless valid
    valid
  end

end
