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
