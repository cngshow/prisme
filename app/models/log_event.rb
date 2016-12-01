class LogEvent < ActiveRecord::Base

  LEVELS = PrismeLogEvent::LEVELS

  validates_presence_of :application_name, :tag, :message, :hostname, :level
  validate :valid_level?

  def valid_level?
    return if LEVELS.values.include?(level)
    errors.add :level_error, "Invalid level. The level must be an integer corresponding to #{LEVELS.map do |k,v| [k, v.to_s] end}"
  end
end

#copy pastables:
# LogEvent.destroy_all