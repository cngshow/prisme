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

  class TermSource
    attr_reader :repoUrl, :groupId, :artifactId, :version

    def initialize(repoUrl:, groupId:, artifactId:, version:)
      @repoUrl = repoUrl
      @groupId = groupId
      @artifactId = artifactId
      @version = version
    end

    def self.init_from_select_key(key)
      vals = key.split('|')
      raise ArgumentError.new('String passed in from select input is blank!') if vals.length != 4
      TermSource.new(repoUrl: vals[0],groupId: vals[1], artifactId: vals[2], version: vals[3])
    end

    def get_full_path
      "#{@repoUrl}/#{@groupId.gsub('.', '/')}/#{@artifactId}/#{@version}/"
    end

    def artifact(ext)
      "#{get_full_path}#{@artifactId}-#{@version}.#{ext}"
    end

    def get_key
      "#{@repoUrl}|#{@groupId}|#{@artifactId}|#{@version}"
    end

    def get_value
      "#{@artifactId} version #{@version}"
    end

    def select_option
      {key: get_key, value: get_value}
    end
  end
end

class KometWar
  attr_reader :groupId, :artifactId, :version, :repo, :package, :classifier

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
    KometWar.new(groupId: vals[0], artifactId: vals[1], version: vals[2], repo: vals[3], classifier: vals[4], package: vals[5])
  end

  def select_key
    "#{groupId}|#{artifactId}|#{version}|#{repo}|#{classifier}|#{package}"
  end

  def select_value
    ret = "#{artifactId}_#{classifier}.#{package}"

    if (classifier.nil? || classifier.length == 0)
      ret = "#{artifactId}.#{package}"
    end
    ret
  end

  def select_option
    {key: select_key, value: select_value}
  end
end
