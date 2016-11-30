json.array!(@log_events) do |log_event|
  json.extract! log_event, :id, :hostname, :application_name, :level, :tag, :message, :acknowledged_by, :acknowledged_on, :ack_comment
  json.url log_event_url(log_event, format: :json)
end
