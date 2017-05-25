# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!
Rails.logger = $log_rails

Dir.glob('./config/post_initialize/*.rb').sort.each do |rb|
  require rb
end
