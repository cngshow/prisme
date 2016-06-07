class PrismeJobQueueController < ApplicationController

  before_action :ensure_services_configured
  skip_after_action :verify_authorized

  def list
  end

  def reload_job_queue_list
    json = JSON.parse PrismeJob.job_name('PrismeCleanupJob', true).order(scheduled_at: :desc).to_json

    json.each do |j|
      if (!j['started_at'].nil? && !j['completed_at'].nil?)
        j[:elapsed_time] = ApplicationHelper.convert_seconds_to_time(Time.parse(j['completed_at']) - Time.parse(j['started_at']))
      else
        j[:elapsed_time] = 'N/A'
      end
    end
    render json: json
  end
end
