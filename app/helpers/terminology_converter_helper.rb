module TerminologyConverterHelper
  include NexusUtility
  CONVERTER_OPTION_PREFIX = 'converter_option_param_'

  def load_drop_down(nexus_params:)
    options = []
    json = NexusUtility.nexus_response_body(params: nexus_params)

    if json && json.has_key?('data')
      json['data'].each do |a|
        options << NexusArtifact.new({g: a['groupId'], a: a['artifactId'], v: a['version']}) # todo CLASSIFIER for IBDFs? ask Dan
      end

      options.sort_by!(&:option_key).reverse!# the reverse will make the most recent versions on top
    else
      $log.debug("EMPTY nexus repository search for #{nexus_params}")
    end

    options
  end

  def load_ibdf_classifiers(nexus_params:)
    options = []
    json = NexusUtility.nexus_response_body(params: nexus_params)

    if json && json.has_key?('data')
      artifactHit = json['data'].first['artifactHits'].first
      artifactHit['artifactLinks'].each do |link|
        if link.has_key?('classifier')
          options << link['classifier']
        end
      end
    else
      $log.debug("EMPTY nexus repository classifier search for #{nexus_params}")
    end
    options
  end
end
