class LogEvent < ActiveRecord::Base
  LEVELS = {ALWAYS: 1, WARN: 2, ERROR: 3, FATAL: 4}

  validates_presence_of :application_name, :tag, :message, :hostname, :level
  validate :valid_level?

  def valid_level?
    return if LEVELS.values.include?(level)
    errors.add :level_error, "Invalid level. The level must be an integer corresponding to #{LEVELS.map do |k,v| [k, v.to_s] end}"
  end
end
