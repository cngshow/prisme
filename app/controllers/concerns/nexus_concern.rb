require 'faraday'

module NexusConcern
  def get_nexus_connection(header = 'application/json')
    props = Service.get_artifactory_props
    nexus_conn = Faraday.new(url: props[PrismeService::NEXUS_ROOT]) do |faraday|
      faraday.request :url_encoded # form-encode POST params
      faraday.use Faraday::Response::Logger, $log
      faraday.headers['Accept'] = header
      faraday.adapter :net_http # make requests with Net::HTTP
      faraday.basic_auth(props[PrismeService::NEXUS_USER], props[PrismeService::NEXUS_PWD])
    end
    nexus_conn
  end

  def get_isaac_cradle_zips
    url_string = $PROPS['ENDPOINT.nexus_lucene_search']
    params = {g: 'gov.vha.isaac.db', r: 'All', e: 'lucene.zip'}
    conn = get_nexus_connection
    response = conn.get(url_string, params)
    json = nil

    begin
      json = JSON.parse response.body
    rescue JSON::ParserError => ex
      if response.status.eql?(200)
        $log.warn("Nexus did not return valid jason with url #{url_string} and params #{params}.  The response was:")
        $log.warn(response.body)
        return []
      end
    end
    ret = []

    if json['totalCount'].to_i > 0
      releases = json['data'].select { |ih| ih['version'] !~ /SNAPSHOT/ }
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
            c = artifact['artifactHits'].first['artifactLinks'].select { |al| al['extension'].eql?('lucene.zip') }.first['classifier']
          rescue => ex
            $log.warn("The nexus repository might have something naughty in it. The troublesome artifact is:")
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
            ret << NexusArtifactSelectOption.new(groupId: g, artifactId: a, version: v, repo: repo, classifier: c, package: 'cradle.zip')
          end
        end
      end

      if ret.empty?
        $log.info('no releases found!!')
      end
    else
      $log.info('no ISAAC cradle zips found!!!')
    end
    ret
  end

end

class TermConvertOption
  attr_reader :groupId, :artifactId, :version, :classifier

  def initialize(groupId, artifactId, version, classifier = nil)
    @groupId = groupId
    @artifactId = artifactId
    @version = version
    @classifier = classifier
  end

  # Builds a JSON object from the dropdown argument
  # @param option_key [String] the key value being parsed
  # @return [String] the argument as a Ruby Hash
  def self.arg_as_json(option_key)
    ret = {}
    args = [:g, :a, :v, :c]
    unless (option_key.nil?)
      option_key.split('|').each_with_index do |arg, idx|
        ret[args[idx]] = arg
      end
    else
      raise StandardError('option_key argument passed was nil.')
    end
    ret
  end

  def option_key
    "#{groupId}|#{artifactId}|#{version}|#{classifier}"
  end

  def option_value
    "#{artifactId}-#{version}#{classifier ? '-' + classifier : ''}"
  end

  def select_option
    {key: option_key, value: option_value}
  end
end

class NexusArtifactSelectOption
  attr_reader :groupId, :artifactId, :version, :repo, :classifier, :package

  def initialize(groupId:, artifactId:, version:, repo:, classifier:, package:)
    @groupId = groupId
    @artifactId = artifactId
    @version = version
    @repo = repo
    @package = package
    @classifier = classifier
  end

  def self.init_from_select_key(key)
    vals = key.split('|')
    raise ArgumentError.new('String passed in from select input is blank!') if vals.length != 6
    NexusArtifactSelectOption.new(groupId: vals[0], artifactId: vals[1], version: vals[2], repo: vals[3], classifier: vals[4], package: vals[5])
  end

  def select_key
    "#{groupId}|#{artifactId}|#{version}|#{repo}|#{classifier}|#{package}"
  end

  def select_value
    ret = "#{artifactId}-#{version}-#{classifier}.#{package}"

    if (classifier.nil? || classifier.length == 0)
      ret = "#{artifactId}-#{version}.#{package}"
    end
    ret
  end

  def select_option
    {key: select_key, value: select_value}
  end
end


class NexusOption
  attr_reader :g, :a, :v, :r, :c, :p

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
    ret = {}
    args = [:g, :a, :v, :r, :c, :p]
    unless (option_key.nil?)
      option_key.split('|').each_with_index do |arg, idx|
        ret[args[idx]] = arg
      end
    else
      raise StandardError('option_key argument passed was nil.')
    end
    ret
  end

  # Builds a JSON object from the dropdown argument
  # @param option_key [String] the key value being parsed
  # @return [String] the argument as a Ruby Hash
  def self.init_from_select_key(key)
    raise ArgumentError.new('String passed in from select input is blank!') if key.scan(/\|/).length != 5
    vals = key.split('|')
    NexusOption.new({g: vals[0], a: vals[1], v: vals[2], r: vals[3], c: vals[4], p: vals[5]})
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
