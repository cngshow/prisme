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

  def time_stats
    stats = request.headers['HTTP_APACHE_TIME']
    # stats = 'D=2265716,t=1490286593518305' #example ssoi header return value
    if stats
      stats = stats.split(',').map do |e| e.split('=') end.to_h
      duration_of_apache_request = stats['D'].to_i/1000000.0
      epoch_time = stats['t'].to_i/1000000.0
      apache_to_rails_delta = (@req_start_time - epoch_time).round(3)
      millis = apache_to_rails_delta.modulo(1).round(3).to_s.split('.').last.to_i.to_s + 'ms'
      @delta_time = ApplicationHelper.convert_seconds_to_time(apache_to_rails_delta) + ' ' + millis
      millis = duration_of_apache_request.modulo(1).round(3).to_s.split('.').last.to_i.to_s + 'ms'
      @apache_time = ApplicationHelper.convert_seconds_to_time(duration_of_apache_request) + ' ' + millis
    end
  end

  def log_level
    level = params[:level].to_sym if Logging::RAILS_COMMON_LEVELS.include? params[:level].to_sym
    if level.nil?
      render text: "Valid log levels are #{Logging::RAILS_COMMON_LEVELS.inspect}.<br><br>Sample invocation: http://localhost:3000/utilities/log_level?level=info"
      return
    end
    ALL_LOGGERS.each do |logger|
      logger.level= level
    end
    render text: "New level set"
  end

  def browser_tz_offset
    tz = params[:tzOffset]
    session[:tzOffset] = tz
    render json: {status: 'done'}
  end

  def prisme_config
    prisme_config = PrismeUtilities.server_config
    prisme_config.merge!({'aitc_environment' => PrismeUtilities.aitc_environment})
    render :json => prisme_config
  end

  # http://localhost:3000/utilities/seed_database?db=localhost
  def seed_services
    ret = nil
    seeds = []
    valid_seeds = %w(localhost va_dev_db aitc_dev_db aitc_sqa_db aitc_test_db)
    db_seed = params[:db]
    v = $VERBOSE
    $VERBOSE = nil
    if valid_seeds.include?(db_seed)
      case db_seed
        when 'localhost'
          load './lib/dbseeds/localhost.rb'
          seeds = SeedData::LOCALHOST
        when 'va_dev_db'
          load './lib/dbseeds/va_dev_db.rb'
          seeds = SeedData::VA_DEV
        when 'aitc_dev_db'
          load './lib/dbseeds/aitc_dev_db.rb'
          seeds = SeedData::AITC_DEV
        when 'aitc_test_db'
          load './lib/dbseeds/aitc_test_db.rb'
          seeds = SeedData::AITC_TEST
        when 'aitc_sqa_db'
          load './lib/dbseeds/aitc_sqa_db.rb'
          seeds = SeedData::AITC_SQA
        else
          ret = 'A valid key was passed but we have not created the corresponding file in the lib/dbseeds'
      end
      $VERBOSE = v
      unless ret
        ret = write_service_seeds(seeds)
      end
    else
      ret = 'bad database seed parameter passed'
    end

    render text: ret
  end

  private

  def setup_time
    @req_start_time = Time.now.to_f
  end

  def write_service_seeds(seeds)
    # truncate the tables and seed them
    Service.destroy_all
    services = []

    seeds.each do |svc|
      service = Service.create(svc[:service])
      services << service

      svc[:props].each_with_index do |props, idx|
        ServiceProperty.create({service_id: service.id, order_idx: idx}.merge(props))
      end
    end

    "<h1>Created Services!</h1><br>#{services.map(&:to_json)}"
  end
end
