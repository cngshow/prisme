require './lib/dbseeds/aitc_dev_db'
require './lib/dbseeds/aitc_sqa_db'
require './lib/dbseeds/aitc_test_db'
require './lib/dbseeds/localhost'
require './lib/dbseeds/va_dev_db'

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

  def prisme_config
    @@config ||= PrismeUtilities.server_config
    render :json => @@config
  end

  # http://localhost:3000/utilities/seed_database?db=localhost
  def seed_services
    ret = nil
    seeds = []
    valid_seeds = %w(localhost va_dev_db aitc_dev_db aitc_sqa_db aitc_test_db)
    db_seed = params[:db]

    if valid_seeds.include?(db_seed)
      case db_seed
        when 'localhost'
          seeds = SeedData::LOCALHOST
        when 'va_dev_db'
          seeds = SeedData::VA_DEV
        when 'aitc_dev_db'
          seeds = SeedData::AITC_DEV
        when 'aitc_test_db'
          seeds = SeedData::AITC_TEST
        when 'aitc_sqa_db'
          seeds = SeedData::AITC_SQA
        else
          ret = 'A valid key was passed but we have not created the corresponding file in the lib/dbseeds'
      end

      unless ret
        ret = write_service_seeds(seeds)
      end
    else
      ret = 'bad database seed parameter passed'
    end

    render text: ret
  end

  private
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
