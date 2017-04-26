require './lib/vuid/vuid'
PrismeJars.load

class VuidController < ApplicationController
  before_action :can_deploy
  # skip_after_action :verify_authorized, only: [:log_event]
  # skip_before_action :verify_authenticity_token, only: [:log_event]

  def index
    @results = VUID.fetch_rows(num_rows: 15)
    # a = VUID.request_vuid(range: 1, reason: 'reason', username: prisme_user.user_name)
    # g = @results
  end

  def request_vuid
    range = params['range']
    reason = params['reason']
    VUID.request_vuid(range: range, reason: reason, username: prisme_user.user_name)
    redirect_to vuid_requests_path
  end

  def ajax_vuid_polling
    #   look at filter results partial
    @results = VUID.fetch_rows(num_rows: 15)
    render partial: 'vuid_results_tbody'
  end

end
