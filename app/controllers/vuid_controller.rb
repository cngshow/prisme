require './lib/vuid/vuid'
PrismeJars.load

class VuidController < ApplicationController
  before_action :can_deploy

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

  def rest_request_vuid
    range = params['range']
    reason = params['reason']
    user = params['username']
    vuids = VUID.request_vuid(range: range, reason: reason, username: user)
    render json: vuids.to_json
  end

  def rest_fetch_vuids
    rows = params['num_vuids']
    rows = 1000 if rows.nil?
    rows = VUID.fetch_rows
    render json: rows.to_json
  end

  def ajax_vuid_polling
    #   look at filter results partial
    @results = VUID.fetch_rows(num_rows: 15)
    render partial: 'vuid_results_tbody'
  end

end
