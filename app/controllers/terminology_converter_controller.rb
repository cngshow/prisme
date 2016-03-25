require 'json'
require 'erb'
# include ApplicationHelper
include NexusConcern

class TerminologyConverterController < ApplicationController
  def setup_last
    @options = load_source_content
    render 'terminology_converter/wizard'
  end

  def setup
    @options = load_source_content
  end

  def process_form
    term_source = params[:terminology_source]
    source = TermSource.init_from_select_key(term_source) unless term_source.nil?
    base_dir = './tmp/vhat-ibdf/'
    source_version = source.version
    loader_version = 'SNAPSHOT-LOADER-VERSION-KMA'
    erb = 'pom.xml.erb'

    # use 'binding' (method in Kernel) which binds the current block for erb so that the local variables are visible to the pom.xml.erb
    pom_result = ERB.new(File.open("#{base_dir}/#{erb}", 'r') { |file| file.read }).result(binding)

    # write the new pom file out
    File.open("#{base_dir}/pom.xml", 'w') {|f| f.write(pom_result) }

    # delete the pom.xml.erb file
    File.delete("#{base_dir}/#{erb}")

    # move zip to nexus
    # download from nexus to temp
    # unzip in temp


    url_string = source.artifact('pom')
    @pom = get_nexus_connection.get(url_string, {}).body
    @pom = pom_result

  end

  def get_repo_zip
    # 'http://localhost:8081/nexus/service/local/artifact/maven/content?g=vhat_ibdf&a=converter&v=LATEST&r=vhat_ibdf&c=vhat_ibdf_converters&e=zip'
    url_string = '/nexus/service/local/artifact/maven/content'
    params = {g: 'vhat_ibdf', a: 'converter', v: 'LATEST', r: 'vhat_ibdf', c: 'vhat_ibdf_converters', e: 'zip'}
    File.open('./tmp/vhat_ibdf.zip', 'w') {|f| f.write(get_nexus_connection.get(url_string, params)) }

  end

  ##################################################################################
  # load the source content from nexus using a lucene search based on the group name
  ##################################################################################
  def load_source_content
    url_string = '/nexus/service/local/lucene/search'
    params = {g: 'gov.vha.isaac.terminology.source.*'}
    response = get_nexus_connection.get(url_string, params)
    json = nil

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError => ex
      if (response.status.eql?(200))
        return response.body
      end
    end

    repo_url = json['repoDetails'].first['repositoryURL']
    # todo what do we do about this gsub!? is this always the case?
    repo_url.gsub!('service/local', 'content')

    # iterate over the results building the sorted TermSource Struct
    hits = json['data']
    data = hits.map { |i| TermSource.new(repoUrl: repo_url, groupId: i['groupId'], artifactId: i['artifactId'], version: i['version']) }.sort_by { |e| [e.get_key] }
    data
  end
end
