require 'uri'

#methods for Prisme, but not Komet go here, for Komet visibility see helpers.rb in rails common.
module PrismeUtilities

  KOMET_APPLICATION = /^rails_komet/
  ISAAC_APPLICATION = /^isaac-rest/
  ALL_APPLICATION = /.*/
  VALID_APPLICATIONS = [KOMET_APPLICATION, ISAAC_APPLICATION, ALL_APPLICATION]

  class << self
    attr_accessor :ssoi_logout_url
    attr_accessor :config
  end

  def self.localize_host(host)
    host.gsub!('0:0:0:0:0:0:0:1', 'localhost')
    host.gsub!('127.0.0.1', 'localhost')
    host
  end

  def self.get_proxy_contexts(tomcat_ar:, application_type:)
    raise ArgumentError.new "Application_type must be a member of PrismeUtilities::VALID_APPLICATIONS!" unless VALID_APPLICATIONS.include? application_type
    uri = nil
    tomcat_ar.service_properties.each do |sp|
      if (sp.key.eql? PrismeService::CARGO_REMOTE_URL)
        uri = URI sp.value
        break
      end
    end
    host = uri.host
    port = uri.port
    contexts = []
    PrismeUtilities.proxy_urls.each do |k|
      uri = URI k['incoming_url_path']
      port = uri.port
      $log.trace(uri.host + " : " + port.to_s)
      contexts << uri.path if (host.eql?(uri.host) && port.to_s.eql?(port.to_s))
      $log.warn("server_config.yaml has a configuration with no context!  Prisme cannot use it for a deploy.") if uri.path.eql? '/'
    end
    $log.info("contexts has #{contexts}")
    $log.warn("I could not find a valid proxy config for host #{host} with port #{port}.  Check prisme's server_config.yml") if contexts.empty?
    contexts.map do |e| e[0].eql?('/') ? e.reverse.chop.reverse : e end.reject do |e| e.empty? end.reject do |e| e !~ application_type end
  end

  def self.proxy_mappings
    URI.proxy_mappings
  end

  def self.application_urls
    server_config['application_urls']
  end

  def self.get_proxy
    server_config['proxy_config_root']['apache_url_proxy']
  end

  def self.proxy_urls
    server_config['proxy_config_root']['proxy_urls']
  end


  def self.server_config
    return PrismeUtilities.config unless PrismeUtilities.config.nil?
    # default the config file location based on the data_directory property
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
    begin
      PrismeUtilities.config = YAML.load_file(config_file)
    rescue => ex
      $log.error("Error reading #{config_file}, error is #{ex}")
      $log.error(ex.backtrace.join("\n"))
    end
    PrismeUtilities.config
  end

  def self.ssoi_logout_path
    logout_url = PrismeUtilities.ssoi_logout_url
    return logout_url unless logout_url.nil?
    config_file = PrismeUtilities.server_config
    return nil unless config_file
    logout_url = config_file[APPLICATION_URLS][SSOI_LOGOUT]
    PrismeUtilities.ssoi_logout_url = URI.valid_url?(url_string: logout_url) ? logout_url : nil
  end

  #Tells if the given uri is up.  If basic authentication is required and not provided false will be returned.
  #The method is light weight and only fetches the headers of a given url.
  #Sample invocation:
  #PrismeUtilities.uri_up?(uri: 'http://www.google.com')
  #PrismeUtilities.uri_up?(uri: "https://vadev.mantech.com:8080/nexus/content/repositories/termdata/gov/vha/isaac/db/vets/1.0/vets-1.0-all.cradle.zip", user: 'user', password: 'password')
  def self.uri_up?(uri:, user: nil, password: nil)
    if uri.is_a? String
      uri = URI uri
    else
      raise "URI must be a a String URI or a URI object" unless uri.is_a? URI
    end
    result = false
    begin
      path = uri.path.empty? ? '/' : uri.path
      result = Net::HTTP.new(uri.host, uri.port)
      result.use_ssl = uri.scheme.eql?('https')
      head = Net::HTTP::Head.new(path, nil)
      head.basic_auth(user, password) if user
      headers = result.request head
      result = headers.kind_of?(Net::HTTPSuccess)
        # Net::HTTP.new(u, p).head('/').kind_of? Net::HTTPOK
    rescue => ex
      $log.warn("I could not check the URL #{uri.path} at port #{uri.port} against path #{uri.path} because #{ex}.")
      result = false
    end
    result
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
  # this method takes the modified matching url paths and returns the proxy path
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

      if (clone.to_s.starts_with?(incoming_url) || (clone.to_s + '/').starts_with?(incoming_url))
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
