module ApplicationHelper


  def self.convert_seconds_to_time(time)
    #    time = time.to_i
    #    time_string = [time/3600, time/60 % 60, time % 60].map{|t| t.to_s.rjust(2,'0')}.join(':')
    #    time_string.sub!(':','h ').sub!(':','m ').concat('s')
    #    time_string.sub!('00h 00m ','')
    #    time_string.sub!('00h ','')
    #    time_string
    time_string = "%02dd %02dh %02dm %02ds"% [
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

  def self.display_time(time)
    ret = ""
    if (!time.nil?)
      converted_time = time + session[:tzOffset].to_i.hours
      ret = converted_time.strftime("%m / %d / %Y %H:%M:%S") << " " << TimeUtils.offset_to_zone(session[:tzOffset])
    end
    ret
  end
end
# load './app/helpers/application_helper.rb'
# include ApplicationHelper