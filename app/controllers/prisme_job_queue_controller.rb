class PrismeJobQueueController < ApplicationController
  def list
  end

  def reload_job_queue_list
    TestJob.set(wait_until: 1.seconds.from_now).perform_later if params['add_test_job']#todo remove this call!
    json = JSON.parse PrismeJob.order(status: :asc, scheduled_at: :desc).limit(30).to_json

    json.each do |j|
      if (!j['started_at'].nil? && !j['completed_at'].nil?)
        j[:elapsed_time] = ApplicationHelper.convert_seconds_to_time(Time.parse(j['completed_at']) - Time.parse(j['started_at']))
      end
    end
    render json: json
  end
end
