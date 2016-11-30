class LogEventsController < ApplicationController
  before_action :set_log_event, only: [:show, :edit, :update, :destroy]
  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token

  # GET /log_events
  # GET /log_events.json
  def index
    @log_events = LogEvent.all
  end

  # GET /log_events/1
  # GET /log_events/1.json
  def show
  end

  # GET /log_events/new
  def new
    @log_event = LogEvent.new
  end

  # GET /log_events/1/edit
  def edit
  end

  # POST /log_events
  # POST /log_events.json
  def create
    @log_event = LogEvent.new(log_event_params)

    respond_to do |format|
      if @log_event.save
        format.html { redirect_to @log_event, notice: 'Log event was successfully created.' }
        format.json { render :show, status: :created, location: @log_event }
      else
        format.html { render :new }
        format.json { render json: @log_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /log_events/1
  # PATCH/PUT /log_events/1.json
  def update
    respond_to do |format|
      if @log_event.update(log_event_params)
        format.html { redirect_to @log_event, notice: 'Log event was successfully updated.' }
        format.json { render :show, status: :ok, location: @log_event }
      else
        format.html { render :edit }
        format.json { render json: @log_event.errors, status: :unprocessable_entity }
      end
    end
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
    def log_event_params
      params.require(:log_event).permit(:hostname, :application_name, :level, :tag, :message, :acknowledged_by, :acknowledged_on, :ack_comment)
    end
end
