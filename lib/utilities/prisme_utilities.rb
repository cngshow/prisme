require 'uri'

module PrismeUtilities
  APPLICATION_URLS = 'application_urls'
  SSOI_LOGOUT = 'ssoi_logout'

  class << self
    attr_accessor :ssoi_logout_url
  end


  def self.proxy_mappings
    URI.proxy_mappings
  end

  def self.server_config
    # default the config file location basd on the data_directory property
    config_file = "#{$PROPS['PRISME.data_directory']}/server_config.yml"

    # if the config file does not exist then fallback to the file in the config directory.
    unless File.exists?(config_file)
      config_file = './config/server_config.yml'
    end

    # now check that the actual config file to use exists. This should never fail but
    # in case it is deleted from source control we do not want to go any further
    unless File.exists? config_file
      $log.warn('No proxy mapping file found. Doing nothing!')
      return nil
    end

    # read the config yml file
    YAML.load_file(config_file)
  end

  def self.ssoi_logout_path
    logout_url = PrismeUtilities.ssoi_logout_url
    return logout_url unless logout_url.nil?
    config_file = PrismeUtilities.server_config
    return nil unless config_file
    logout_url = config_file[APPLICATION_URLS][SSOI_LOGOUT]
    PrismeUtilities.ssoi_logout_url = URI.valid_url?(url_string: logout_url) ? logout_url : nil
  end

end

module URI
  # these keys are used in the server_config yaml file to map incoming urls to their corresponding proxy location
  PROXY_CONFIG_ROOT = 'proxy_config_root'
  APACHE_URL_PROXY = 'apache_url_proxy'
  PROXY_URLS = 'proxy_urls'
  INCOMING_URL_PATH = 'incoming_url_path'
  PROXY_LOCATION = 'proxy_location'

  class << self
    attr_accessor :proxy_mappings
  end

  #**
  # this method takes the modifies matching url paths and returns the proxy path
  def proxify
    # proxy_mappings are loaded one time once all of the urls listed are valid.
    if URI.proxy_mappings.nil?
      config_file = PrismeUtilities.server_config
      return self unless config_file

      # read the config yml file and pull out the proxy_root properties
      $log.debug('initializing the proxy mappings to:')
      URI.proxy_mappings = config_file[PROXY_CONFIG_ROOT]
      $log.debug("PROXY MAPPINGS ARE: #{URI.proxy_mappings.inspect}")

      # pull out the apache host url and validate it
      apache_host = URI.proxy_mappings[APACHE_URL_PROXY]
      $log.debug("apache host is #{apache_host}")
      valid_urls = URI.valid_url?(url_string: apache_host)

      # pull out all of the incoming urls and validate them
      URI.proxy_mappings[PROXY_URLS].each do |url_hash|
        url = url_hash[INCOMING_URL_PATH]
        valid_urls = valid_urls & URI.valid_url?(url_string: url) # & will not short circuit
      end

      # bail out if we have any invalid urls configured
      unless valid_urls
        URI.proxy_mappings = nil
        return self
      end
      
      # sort the urls from longest to shortest for  proxifying
      URI.proxy_mappings[PROXY_URLS].sort! do |a, b|
        b[INCOMING_URL_PATH].length <=> a[INCOMING_URL_PATH].length
      end
      
      # freeze the configuration
      URI.proxy_mappings.freeze
      $log.debug(URI.proxy_mappings.inspect)
    end
    
    # ensure that the apache url has leading and trailing slashes
    apache_path = URI.proxy_mappings[APACHE_URL_PROXY].clone
    apache_path << '/' unless apache_path.last.eql? '/'
    
    # iterate the incoming urls for a match that needs to be proxified
    URI.proxy_mappings[PROXY_URLS].each do |url_hash|
      incoming_url = url_hash[INCOMING_URL_PATH]
      location = url_hash[PROXY_LOCATION]
      clone = self.clone

      if clone.to_s.starts_with?(incoming_url)
        #we found our match!!
        apache_uri = URI(apache_path)
        clone.path << '/' unless clone.path.last.eql? '/'

        # get the incoming url as a URI, check formatting and pull out the context
        matched_uri = URI(incoming_url)
        matched_uri.path << '/' if matched_uri.path.empty?
        matched_uri.path << '/' unless matched_uri.path.last.eql? '/'
        context = matched_uri.path

        # if we have a location that contains a context then ensure leading and trailing slashes
        unless location.eql? '/'
          location = '/' + location unless location.first.eql? '/'
          location << '/' unless location.last.eql? '/'
        end

        # operating off of the clone substitute the context with the location and ensure that the
        # scheme, port, and host for the clone lines up with the proxy configuration for apache
        clone.path.sub!(context, location)
        clone.scheme = apache_uri.scheme
        clone.port = apache_uri.port
        clone.host = apache_uri.host
        return clone
      end
    end
    $log.warn("No proxy mapping found for #{self}, returning self.")
    self
  end
end
#load('./lib/utilities/prisme_utilities.rb')
# URI('https://cris.com').proxify
# URI.proxy_mappings = nil

#works:
# URI('https://vaausappctt704.aac.va.gov:8080/komet_b/foo/faa').proxify

#irb(main):011:0> URI('https://vaausappctt704.aac.va.gov:8080/komet_b/').proxify
#=> #<URI::HTTPS https://vaauscttweb81.aac.va.gov/server_1_rails_fazzle/>
#    irb(main):012:0> URI('https://vaausappctt704.aac.va.gov:8080/komet_b').proxify
