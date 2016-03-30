class PrismeJobQueueController < ApplicationController
  def list
  end

  def reload_job_queue_list
    json = PrismeJob.order(status: :asc, scheduled_at: :desc).limit(30).to_json
    render json: json
  end
end
