require './lib/vuid/vuid'
# PrismeJars.load

class VuidController < ApplicationController
  before_action :can_get_vuids
  REASON_PROMPT = 'Enter the Reason for this VUID Request'

  def index
  end

  def request_vuid
    range = params['range'].to_i rescue 0
    reason = params['reason']
    vuid = nil
    too_big = range > 1000000
    bad_reason = reason.eql?(REASON_PROMPT) || reason.to_s.empty?
    bad_range = range  <= 0
    if (bad_reason || bad_range || too_big)
      error = ''
      error << 'Invalid VUID reason!<br>' if bad_reason
      error << 'VUID range cannot exceed 1 million!<br>' if too_big
      error << 'VUID range is invalid!' if bad_range
      vuid =  VUID::VuidResult.new(nil, nil, nil, nil, nil, nil, nil, error)
    else
      vuid = VUID.request_vuid(range: range, reason: reason, username: prisme_user.user_name)
    end
    if(vuid.error)
      $log.error("The user #{prisme_user.user_name} requested a VUID that failed to be created. Reason: #{vuid.error}")
      flash_alert(message: vuid.error)
    end
    redirect_to vuid_requests_path
  end


  def ajax_vuid_polling
    #   look at filter results partial
    row_limit = params['row_limit'].to_i
    @results = VUID.fetch_rows(num_rows: row_limit)
    render partial: 'vuid_results_tbody'
  end

end
