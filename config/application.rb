$CLASSPATH << './lib/jars/ojdbc7.jar'
require File.expand_path('../boot', __FILE__)

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
#comment line below out if you do not want active record
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

require './lib/rails_common/props/prop_loader' #Grant visibility to $PROPS at this level.
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsPrisme
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.active_job.queue_adapter = :sucker_punch

    oracle_yaml = (RbConfig::CONFIG["host_os"].eql?('mswin32')) ? "#{Rails.root}/config/oracle_database.yml" :$PROPS['PRISME.data_directory'] + '/oracle_database.yml'
    self.paths['config/database'] = oracle_yaml if (File.exists?(oracle_yaml))
    $database = (File.exists?(oracle_yaml)) ? 'ORACLE' : 'H2'
    puts "********************************************** I am raking against #{$database}"
    #http://stackoverflow.com/questions/4204724/strategies-for-overriding-database-yml
  end
end
