class UtilitiesController < ApplicationController
  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token
  #warm up apache
  def warmup
    @headers = {}
    @warmup_count = $PROPS['PRISME.warmup_apache'].to_i
    request.headers.each do |elem|
      @headers[elem.first.to_s] = elem.last.to_s
    end
    respond_to do |format|
      format.html # list_headers.html.erb
      format.json { render :json => params['counter'] }
    end
  end

end
