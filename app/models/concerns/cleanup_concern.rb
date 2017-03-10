module Cleanup

  def cleanup(older_than_in_days = 90)
    begin
      older_than_in_days = older_than_in_days.days.ago
      $log.info("Cleaning up all records in #{self} table older than #{older_than_in_days}.")
      cnt = self.where('created_at < ?', *[older_than_in_days]).delete_all
      $log.info("#{cnt} #{self} deleted.")
    rescue => ex
      $log.warn("Cleanup in #{self} table failed. #{ex}")
      $log.warn(ex.backtrace.join("\n"))
    end
  end

end