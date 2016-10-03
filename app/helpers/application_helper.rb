require 'json'

module ApplicationHelper
  NOTIFY = 'notify_'

  def flash_notify(msg, **addl_settings)
    options = {message: msg}
    settings = {
        element: 'body',
        # position: null,
        type: 'info',
        allow_dismiss: false,
        newest_on_top: false,
        showProgressbar: false,
        placement: {
            from: 'top',
            align: 'right'
        },
        offset: 20,
        spacing: 10,
        z_index: 1031,
        delay: 5000,
        timer: 1000,
        url_target: '_blank',
        # mouse_over: null,
        animate: {
            enter: 'animated fadeInDown',
            exit: 'animated fadeOutUp'
        },
        # onShow: null,
        # onShown: null,
        # onClose: null,
        # onClosed: null,
        icon_type: 'class'
    }

    name = "#{NOTIFY}#{Time.now.to_i}"
    settings.merge!(addl_settings)
    flash[name] = [options, settings]
  end

  def show_flash_notify
    ret = ''
    flash.each do |name, vals|
      show_flash = true

      if name.is_a?(String) && name.start_with?(NOTIFY)
        options = vals.first.to_json
        settings = vals.last.to_json
        flash.discard(name)
      else
        show_flash = false
      end

      if show_flash
        ret << "flash_notify(#{options}, #{settings});"
      end
    end
    ret
  end

  def errors_to_flash(errors)
    retval = []
    errors.each { |attr, error_array|
      error_array = [error_array] unless error_array.is_a? Array
      formatted_attr = attr.to_s.gsub('_', ' ').capitalize
      retval << error_array.map { |elem|
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

  def self.display_time(time)
    ret = ''
    if time
      converted_time = time + session[:tzOffset].to_i.hours
      ret = converted_time.strftime('%m/%d/%Y %H:%M:%S') << ' ' << TimeUtils.offset_to_zone(session[:tzOffset])
    end
    ret
  end

  def prisme_user
    @ssoi ? user_session(UserSession::SSOI_USER) : current_user
  end
end
# load './app/helpers/application_helper.rb'
# include ApplicationHelper