module TerminologyConverterHelper
  include NexusConcern
  CONVERTER_OPTION_PREFIX = "converter_option_param_"

  def load_drop_down(nexus_params: nexus_params)
    url_string = '/nexus/service/local/lucene/search'
    options = []
    response = get_nexus_connection.get(url_string, nexus_params)
    json = nil

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError => ex
      if (response.status.eql?(200))
        return response.body
      end
    end

    if (json && json.has_key?('data'))
      json['data'].each do |a|
        options << TermConvertOption.new(a['groupId'], a['artifactId'], a['version']) # todo CLASSIFIER for IBDFs? ask Dan
      end

      options.sort_by!(&:option_key).reverse!# the reverse will make the most recent versions on top
    else
      $log.debug("EMPTY nexus repository search for #{url_string}&#{nexus_params}")
    end

    options
  end

  def load_ibdf_classifiers(nexus_params: nexus_params)
    url_string = '/nexus/service/local/lucene/search'
    options = []
    response = get_nexus_connection.get(url_string, nexus_params)
    json = nil

    begin
      json = JSON.parse(response.body)
    rescue JSON::ParserError => ex
      if (response.status.eql?(200))
        return response.body
      end
    end

    if (json && json.has_key?('data'))
      artifactHit = json['data'].first['artifactHits'].first
      artifactHit['artifactLinks'].each do |link|
        if link.has_key?('classifier')
          options << link['classifier']
        end
      end
    else
      $log.debug("EMPTY nexus repository classifier search for #{url_string}&#{nexus_params}")
    end
    options
  end
end
