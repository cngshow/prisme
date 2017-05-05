Apipie.configure do |config|
  config.app_name = 'RailsPrisme'
  config.api_base_url = ''
  config.doc_base_url = '/apipie'
  config.app_info = 'Prisme API documentation'
  # where is your API defined?
  #config.api_controllers_matcher = "#{Rails.root}/app/controllers/**/*.rb"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/{[!concerns/]**/*,*}.rb" #https://github.com/Apipie/apipie-rails/issues/347
end
$API_PIE_ROUTES = {}
class APIString
  def initialize(string)
    @s = string
  end

  def to_s
    ERB.new(@s.to_s).result
  end

  def strip_heredoc
    to_s.strip_heredoc
  end

  def method_missing(m)
    @s.send(m)
  end
end

=begin
a = APIString.new('    dddd  ')
 If we need to add in concerns:

# users_module_concern.rb
module UsersModule
  extend Apipie::DSL::Concern
=end