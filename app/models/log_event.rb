class LogEvent < ActiveRecord::Base

  LEVELS = PrismeLogEvent::LEVELS

  validates_presence_of :application_name, :tag, :message, :hostname, :level
  validate :valid_level?

  TAG = :tag
  HOSTNAME = :hostname
  APPLICATION_NAME = :application_name
  UNIQUEABLE_COLUMS = [TAG, HOSTNAME, APPLICATION_NAME]


  def valid_level?
    return if LEVELS.values.include?(level)
    errors.add :level_error, "Invalid level. The level must be an integer corresponding to #{LEVELS.map do |k,v| [k, v.to_s] end}"
  end

  def self.cleanup(older_than_in_days = 90)
    begin
      older_than_in_days = older_than_in_days.days.ago
      $log.info("Cleaning up all records in log event table older than #{older_than_in_days}.")
      cnt = LogEvent.where('created_at < ?', *[older_than_in_days]).delete_all
      $log.info("#{cnt} log events deleted.")
    rescue => ex
      $log.warn("Cleanup in log event table failed. #{ex}")
      $log.warn(ex.backtrace.join("\n"))
    end
  end

  def self.unique_fetch(column:)
    raise ArgumentError.new("Column #{column} is invalid.  Must be one of #{UNIQUEABLE_COLUMS}") unless UNIQUEABLE_COLUMS.include? column
    rval = LogEvent.uniq.pluck(column)
    $log.trace("unique_fetch returning #{rval} for column #{column}")
    rval
  end


end



#copy pastables:
# load('./app/models/log_event.rb')
# LogEvent.destroy_all