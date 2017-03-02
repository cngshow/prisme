require 'uri'

#methods for Prisme, but not Komet go here, for Komet visibility see helpers.rb in rails common.
module PrismeUtilities

  KOMET_APPLICATION = /^rails_komet/
  ISAAC_APPLICATION = /^isaac-rest/
  ALL_APPLICATION = /.*/
  VALID_APPLICATIONS = [KOMET_APPLICATION, ISAAC_APPLICATION, ALL_APPLICATION]

  class << self
    #these do leak internal state.  In most cases you should call the corresponding method below to get a defensive copy
    #of your data structure
    attr_accessor :ssoi_logout_url
    attr_accessor :config #server_config.yml
    attr_accessor :aitc_env #aitc_environment.yml
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
    contexts.map do |e|
      e[0].eql?('/') ? e.reverse.chop.reverse : e
    end.reject do |e|
      e.empty?
    end.reject do |e|
      e !~ application_type
    end
  end

  def self.proxy_mappings
    URI.proxy_mappings
  end

  def self.load_yml_file(config_file, error_message)
    begin
      if File.exists?(config_file)
        hash = YAML.load_file(config_file)
      else
        $log.debug("Config file #{config_file} does not exist!!")
      end
    rescue => ex
      $log.error(error_message)
      $log.error(ex.backtrace.join("\n"))
    end
    hash
  end

  def self.synch_group_data(dump_data = false)
    persistent_group_file = "#{$PROPS['PRISME.data_directory']}/group_data.yml"
    group_file = './config/group_data.yml'
    config_file = File.exists?(persistent_group_file) ? persistent_group_file : group_file
    groups = PrismeUtilities::load_yml_file(config_file, "Group data might not have been created but PRISME will continue to start.")
    if groups.nil?
      $log.info("No group yaml file avaliable for loading!")
      return
    end
    created_groups = 0
    skipped_groups = 0
    updated_sites = 0
    group_ids = groups.map do |group|
      group['id']
    end
    db_group_ids = VaGroup.all.to_a.map do |e|
      e.id
    end
    groups_to_delete = db_group_ids - group_ids
    $log.always("Attempting to delete the following groups: #{groups_to_delete}")
    deleted = VaGroup.where('id in (?)', groups_to_delete).destroy_all.length
    $log.always("Deleted #{deleted} groups.")
    groups.each do |group_hash|
      group = VaGroup.new(group_hash)
      if (VaGroup.exists? group.id)
        db_group = VaGroup.find(group.id)
        if (db_group.eql? group)
          skipped_groups += 1
          $log.debug("I am skipping the group from #{config_file} with group id #{group.id}.  It already exists.")
        else
          #we need to update db_site, and record the update
          begin
            db_group.update! name: group.name, member_sites: group.member_sites, member_groups: group.member_groups
            updated_sites += 1
            $log.always("I updated the group with group id #{db_group.id}")
          rescue => ex
            $log.always("Update failed for the group with group id #{db_group.id}")
            $log.always(ex.message)
          end
        end
      else
        saved = true
        begin
          group.save!
          $log.always("I saved the group with group id #{group.id}")
        rescue => ex
          saved = false
          $log.warn("Save failed for #{group.inspect}")
          $log.warn(ex.message)
        end
        created_groups += 1 if saved
        skipped_groups += 1 unless saved
      end
    end
    if dump_data
      dump_file = File.basename(config_file, '.*')
      dump_file = "#{$PROPS['PRISME.data_directory']}/#{dump_file}_#{Time.now.to_i}.yml"
      File.open(dump_file, 'w') do |f|
        f.write(VaGroup.all.to_a.map do |e|
          {'id' => e.va_site_id, 'name' => e.name, 'member_sites' => e.get_site_ids, 'member_groups' => e.get_group_ids}
        end.to_yaml)
      end
    end
    r_val = {created_groups: created_groups, skipped_groups: skipped_groups, updated_groups: updated_sites, deleted_groups: deleted}
    $log.always("Group final results: #{r_val}")
    r_val
  end

  #todo When the validators for the site model grow change to bang(!) methods like synch_group_data above
  def self.synch_site_data(dump_data = false)
    persistent_site_file = "#{$PROPS['PRISME.data_directory']}/site_data.yml"
    site_file = './config/site_data.yml'
    config_file = File.exists?(persistent_site_file) ? persistent_site_file : site_file
    sites = PrismeUtilities::load_yml_file(config_file, "Site data might not have been created but PRISME will continue to start.")
    if sites.nil?
      $log.info("No site yaml file avaliable for loading!")
      return
    end
    created_sites = 0
    skipped_sites = 0
    updated_sites = 0
    site_ids = sites.map do |site|
      site['va_site_id']
    end
    db_site_ids = VaSite.all.to_a.map do |e|
      e.va_site_id
    end
    sites_to_delete = db_site_ids - site_ids
    $log.always("Attempting to delete the following sites: #{sites_to_delete}")
    deleted = VaSite.where('va_site_id in (?)', sites_to_delete).destroy_all.length
    $log.always("Deleted #{deleted} sites.")
    sites.each do |site_hash|
      site = VaSite.new(site_hash)
      if (VaSite.exists? site.va_site_id)
        db_site = VaSite.find(site.va_site_id)
        if (db_site.eql? site)
          skipped_sites += 1
          $log.debug("I am skipping the site from #{config_file} with site id #{site.va_site_id}.  It already exists")
        else
          #we need to update db_site, and record the update
          updated = db_site.update site_hash
          updated_sites += 1 if updated
          $log.always("I updated the site with site id #{db_site.va_site_id}")
        end

      else
        saved = site.save
        created_sites += 1 if saved
        skipped_sites += 1 unless saved
      end
    end
    if dump_data
      dump_file = File.basename(config_file, '.*')
      dump_file = "#{$PROPS['PRISME.data_directory']}/#{dump_file}_#{Time.now.to_i}.yml"
      File.open(dump_file, 'w') do |f|
        f.write(VaSite.all.to_a.map do |e|
          {'va_site_id' => e.va_site_id, 'name' => e.name, 'site_type' => e.site_type, 'message_type' => e.message_type}
        end.to_yaml)
      end
    end
    r_val = {created_sites: created_sites, skipped_sites: skipped_sites, updated_sites: updated_sites, deleted_sites: deleted}
    $log.always("Site final results: #{r_val}")
    r_val
  end

  def self.prisme_super_user
    users = load_yml_file("#{$PROPS['PRISME.data_directory']}/prisme_super_user.yml", "Administrative Users have not been created but PRISME will continue to start.")
    return if users.nil?
    begin
      # if the config file does not exist then fallback to the file in the config directory.
      users['users'].each do |u|
        su = User.find_or_create_by(email: u['email'], admin_role_check: true)
        su.password = u['password']
        su.save!
        su.add_role(Roles::SUPER_USER)
      end
    rescue => ex
      $log.error("Not all administrative Users have been created but PRISME will continue to start. The exception is #{ex}")
      $log.error(ex.backtrace.join("\n"))
    end
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

  def self.aitc_environment
    return (HashWithIndifferentAccess.new PrismeUtilities.aitc_env).deep_dup unless PrismeUtilities.aitc_env.nil?
    PrismeUtilities.aitc_env = PrismeUtilities.fetch_yml 'aitc_environment.yml'
    (HashWithIndifferentAccess.new PrismeUtilities.aitc_env).deep_dup
  end

  def self.server_config
    return (HashWithIndifferentAccess.new PrismeUtilities.config).deep_dup unless PrismeUtilities.config.nil?
    PrismeUtilities.config = PrismeUtilities.fetch_yml 'server_config.yml'
    (HashWithIndifferentAccess.new PrismeUtilities.config).deep_dup
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

  def self.fetch_yml(base_file)
    yml_file = PrismeUtilities.which_file(base_file)
    if yml_file.nil?
      $log.warn("No yml file found! #{base_file}")
      return nil
    end
    # read the yml file
    begin
      return HashWithIndifferentAccess.new YAML.load(ERB.new(File.read(yml_file)).result)
    rescue => ex
      $log.error("Error reading #{yml_file}, error is #{ex}")
      $log.error(ex.backtrace.join("\n"))
    end
    nil
  end

  #given a base file selects the prismeData variant over the config variant
  def self.which_file(base_file)
    # default the config file location based on the data_directory property
    file = "#{$PROPS['PRISME.data_directory']}/#{base_file}"

    # if the config file does not exist then fallback to the file in the config directory.
    unless File.exists?(file)
      file = "./config/#{base_file}"
    end
    unless File.exists? file
      $log.warn("#{base_file} not found.")
      return nil
    end
    file
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
# PrismeUtilities.aitc_environment
# URI('https://cris.com').proxify
# URI.proxy_mappings = nil

#works:
# URI('https://vaausappctt704.aac.va.gov:8080/komet_b/foo/faa').proxify

#irb(main):011:0> URI('https://vaausappctt704.aac.va.gov:8080/komet_b/').proxify
#=> #<URI::HTTPS https://vaauscttweb81.aac.va.gov/server_1_rails_fazzle/>
#    irb(main):012:0> URI('https://vaausappctt704.aac.va.gov:8080/komet_b').proxify
