require 'faraday'

module NexusUtility
  private
  def self.nexus_response_body(params:)
    url_string = $PROPS['ENDPOINT.nexus_lucene_search']
    conn = nexus_connection
    response = conn.get(url_string, params)
    json = nil

    begin
      json = JSON.parse response.body
    rescue JSON::ParserError
      if response.status.eql?(200)
        $log.warn("Nexus did not return valid jason with url #{url_string} and params #{params}.  The response was:")
        $log.warn(response.body)
      end
    end
    json
  end

  def self.nexus_connection(header = 'application/json')
    props = Service.get_artifactory_props
    Faraday.new(url: props[PrismeService::NEXUS_ROOT]) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.use Faraday::Response::Logger, $log
      faraday.headers['Accept'] = header
      faraday.adapter :net_http # make requests with Net::HTTP
      faraday.basic_auth(props[PrismeService::NEXUS_USER], props[PrismeService::NEXUS_PWD])
    end
  end


class DbBuilderSupport < PrismeCacheManager::ActivitySupport
    include Singleton

    def get_ibdf_files
      @work_lock.synchronize do
        return @ibdf_files
      end
    end

    def get_ochre_metadatas
      @work_lock.synchronize do
        return @ochre_metadatas
      end
    end

    def do_work
      @work_lock.synchronize do
        $log.debug('I am doing my work!')
        @ochre_metadatas = load_ochre_metadatas
        @ibdf_files = load_ibdf_files
        $log.always("DBBuilder ochre #{@ochre_metadatas.inspect}")
        $log.always("DBBuilder ibdf #{@ibdf_files.inspect}")

        $log.debug('I am done!')
      end
    end

    def register
      duration = $PROPS['PRISME.db_builder_cache'].to_i.minutes
      @worker.register_work('DbBuilderSupport', duration, @dirty_lambda) do
        do_work
      end
    end

    private
    def initialize
      @worker = PrismeCacheManager::CacheWorkerManager.instance.fetch(PrismeCacheManager::DB_BUILDER)
      @worker.register_work_complete(observer: self)
      @work_lock = @worker.work_lock
      super(@work_lock)
    end

    def load_ibdf_files
      options = []
      params = {g: 'gov.vha.isaac.terminology.converted', repositoryId: 'termdata'}
      json = NexusUtility.nexus_response_body(params: params)

      if json && json.has_key?('data')
        json['data'].each do |data|
          opt = {g: data['groupId'], a: data['artifactId'], v: data['version']}
          hits = data['artifactHits'].first['artifactLinks'].select {|d| d['extension'].eql?('ibdf.zip')}
          hits.each do |hit|
            option = opt.clone
            option[:c] = hit['classifier'] ||= ''
            options << NexusArtifact.new(option)
          end
        end

        options.sort_by!(&:option_key).reverse!
      else
        $log.debug("EMPTY nexus repository search for #{params}")
      end

      options
    end

    def load_ochre_metadatas
      options = []
      params = {g: 'gov.vha.isaac.ochre.modules', a: 'ochre-metadata', repositoryId: 'releases'}
      json = NexusUtility.nexus_response_body(params: params)
      $log.always("json data #{json}")

      if json && json.has_key?('data')
        json['data'].each do |d|
          options << NexusArtifact.new({g: d['groupId'], a: d['artifactId'], v: d['version']})
        end

        options.sort_by!(&:option_key).reverse! #the reverse will make the most recent versions on top
      else
        $log.debug("EMPTY nexus repository lucene search for #{params}")
      end

      options
    end

  end

  class DeployerSupport < PrismeCacheManager::ActivitySupport
    include Singleton

    def get_komet_wars
      @work_lock.synchronize do
        return @komet_wars
      end
    end

    def get_isaac_wars
      @work_lock.synchronize do
        return @isaac_wars
      end
    end

    def get_isaac_dbs
      @work_lock.synchronize do
        return @isaac_dbs
      end
    end

    def do_work
      @work_lock.synchronize do
        $log.debug('I am doing my work!')
        @komet_wars = get_nexus_wars(app: :komet_wars)
        @isaac_wars = get_nexus_wars(app: :isaac_wars)
        @isaac_dbs = get_isaac_cradle_zips
        $log.debug('I am done!')
      end
    end

    def register
      duration = $PROPS['PRISME.app_deployer_cache'].to_i.minutes
      @worker.register_work('DeployerSupport', duration, @dirty_lambda) do
        do_work
      end
    end

    private
    def initialize
      @worker = PrismeCacheManager::CacheWorkerManager.instance.fetch(PrismeCacheManager::APP_DEPLOYER)
      @worker.register_work_complete(observer: self)
      @work_lock = @worker.work_lock
      super(@work_lock)
    end

    def get_nexus_wars(app:)
      params_hash = {:komet_wars => {g: 'gov.vha.isaac.gui.rails', a: 'rails_komet', repositoryId: 'releases', p: 'war'},
                     :isaac_wars => {g: 'gov.vha.isaac.rest', a: 'isaac-rest', repositoryId: 'releases', p: 'war'}, }
      # :isaac_dbs => {g: 'gov.vha.isaac.db', r: 'All', e: 'lucene.zip'}
      params = params_hash[app]
      json = NexusUtility.nexus_response_body(params: params)
      return nil unless json #why nil and not []?
      ret = []

      if json['totalCount'].to_i > 0
        json['data'].each do |artifact|
          g = artifact['groupId']
          a = artifact['artifactId']
          v = artifact['version']
          lr = artifact['latestRelease'] # use this for styling??
          hits = artifact['artifactHits'].first
          repo = hits['repositoryId']
          links = hits['artifactLinks']

          # only include war files
          links.keep_if {|h| h['extension'] == 'war'}.each do |h|
            include_war = true
            if a =~ /komet/i && h['classifier'].eql?('c')
              include_envs = ($PROPS['PRISME.komet_c_include_env']).split(',').map(&:strip) rescue []
              include_war = include_envs.include? PRISME_ENVIRONMENT
            end

            if include_war
              ret << NexusArtifact.new(g: g, a: a, v: v, r: repo, c: h['classifier'], p: h['extension'])
            end
          end
        end
      else
        $log.info('no war files found!!!')
      end
      ret
    end

    def get_isaac_cradle_zips
      json = NexusUtility.nexus_response_body(params: {g: 'gov.vha.isaac.db', r: 'All', e: 'lucene.zip'})
      return [] unless json # the wars returns nil and not [] ??!
      ret = []

      if json['totalCount'].to_i > 0
        releases = json['data'].select {|ih| ih['version'] !~ /SNAPSHOT/}
        nexus_url = Service.get_artifactory_props[PrismeService::NEXUS_PUBLICATION_URL]
        nexus_url << '/' unless nexus_url.last.eql? '/'

        if releases.length > 0
          releases.each do |artifact|
            g = artifact['groupId']
            a = artifact['artifactId']
            v = artifact['version']
            repo = artifact['latestReleaseRepositoryId']
            c = nil
            begin
              c = artifact['artifactHits'].first['artifactLinks'].select {|al| al['extension'].eql?('lucene.zip')}.first['classifier']
            rescue => ex
              $log.warn('The nexus repository might have something naughty in it. The troublesome artifact is:')
              $log.warn(artifact.inspect)
            end

            url = nexus_url.clone
            url << g.gsub('.', '/') << '/'
            url << a << '/'
            url << v << '/'
            url << a << '-' << v
            url << '-' << c if c
            url << '.cradle.zip'
            nexus_props = Service.get_artifactory_props
            nexus_user = nexus_props[PrismeService::NEXUS_USER]
            nexus_passwd = nexus_props[PrismeService::NEXUS_PWD]
            if PrismeUtilities.uri_up?(uri: url, user: nexus_user, password: nexus_passwd)
              ret << NexusArtifact.new(g: g, a: a, v: v, r: repo, c: c, p: 'cradle.zip')
            end
          end
        end

        if ret.empty?
          $log.info('no releases found!!')
        end
      else
        $log.info('no ISAAC cradle zips found!!!')
      end
      ret.sort_by!(&:option_key).reverse! # the reverse will make the most recent versions on top
      ret
    end
  end

  class NexusArtifact
    attr_reader :g, :a, :v, :r, :c, :p
    alias_method :groupId, :g
    alias_method :artifactId, :a
    alias_method :version, :v
    alias_method :repo, :r
    alias_method :classifier, :c
    alias_method :package, :p

    def initialize(**data)
      # group, artifact, and version are required
      raise StandardError('Invalid arguments passed. The nexus data must contain :g, :a, and :v at a minimum.') unless [:g, :a, :v].all? {|s| data.key? s}

      # set all of the data points
      @g = data[:g]
      @a = data[:a]
      @v = data[:v]
      @r = data[:r] ||= '' #repo
      @c = data[:c] ||= '' #classifier
      @p = data[:p] ||= '' #package
    end

    # Builds a JSON object from the dropdown argument
    # @param option_key [String] the key value being parsed
    # @return [String] the argument as d Ruby Hash
    def self.arg_as_json(option_key)
      HashWithIndifferentAccess.new(init_from_select_key(option_key).as_json)
    end

    def self.init_from_select_key(key)
      raise ArgumentError.new('String passed in from select input is blank!') if key.scan(/\|/).length != 5
      vals = key.split('|')
      NexusArtifact.new({g: vals[0], a: vals[1], v: vals[2], r: vals[3], c: vals[4], p: vals[5]})
    end

    def option_key
      "#{g}|#{a}|#{v}|#{r}|#{c}|#{p}"
    end

    # drop down display shows artifact-version and appends the classifier and packaging if available
    def option_value
      ret = "#{a}-#{v}"
      ret << "-#{c}" unless c.empty?
      ret << ".#{p}" unless p.empty?
      ret
    end

    def select_option
      {key: option_key, value: option_value}
    end
  end

    # alias_method :select_value, :option_value
    # alias_method :select_key, :option_key
end
