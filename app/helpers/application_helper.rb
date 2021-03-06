require './lib/time/time_utils'

module ApplicationHelper
  include BootstrapNotifier

  def errors_to_flash(errors)
    retval = []
    errors.each {|attr, error_array|
      error_array = [error_array] unless error_array.is_a? Array
      formatted_attr = attr.to_s.gsub('_', ' ').capitalize
      retval << error_array.map {|elem|
        formatted_attr += "\t" + elem.to_s
      }
    }
    retval.flatten
  end

  def self.convert_seconds_to_time(time)
    time_string = '%02dd %02dh %02dm %02ds'% [
        time.to_i/ (60*60*24),
        time.to_i/ (60*60) % 24,
        time.to_i/ 60 % 60,
        time.to_i % 60
    ]
    time_string.sub!('00d 00h 00m ', '')
    time_string.sub!('00d 00h ', '')
    time_string.sub!('00d ', '')
    time_string
  end

  def display_time(time)
    ret = ''
    if time
      converted_time = time + session[:tzOffset].to_i.hours
      ret = converted_time.strftime('%m/%d/%Y %H:%M:%S') << ' ' << TimeUtils.offset_to_zone(session[:tzOffset])
    end
    ret
  end

  def ssoi?
    !user_session(UserSession::SSOI_USER).nil?
  end

  def prisme_user
    ssoi? ? SsoiUser.fetch_user(user_session(UserSession::SSOI_USER)) : current_user
  end

  #like #devise_controller?
  def utility_controller?
    is_a? ::UtilitiesController
  end

  def update_caches
    CACHE_ACTIVITIES.each_pair do |app, options|
      if (options.last.nil? || (self.send options.last)) #self.send options.last is the role check (:any_administrator?)
        $log.trace("About to wake up #{app} activity thread")
        PrismeCacheManager::CacheWorkerManager.instance.fetch(app).do_work
      end
    end
  end

  def log_user_activity
    if prisme_user && !request.xhr?
      user_name = prisme_user.user_name
      UserActivity.new({username: user_name, last_activity_at: Time.now, request_url: request.original_url}).save
      count = UserActivity.where('username = ?', user_name).count
      trim_count = $PROPS['PRISME.user_activity_trim'].to_i

      if count > trim_count
        UserActivity.where('username = ?', user_name).order('last_activity_at ASC').first(count - trim_count).each {|r| r.destroy}
      end
    end
  end
end
