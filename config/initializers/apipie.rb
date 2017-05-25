Apipie.configure do |config|
  config.app_name = 'RailsPrisme'
  config.api_base_url = ''
  config.doc_base_url = '/apipie'
  config.app_info = 'Prisme API documentation'
  # where is your API defined?
  #config.api_controllers_matcher = "#{Rails.root}/app/controllers/**/*.rb"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/{[!concerns/]**/*,*}.rb" #https://github.com/Apipie/apipie-rails/issues/347
end