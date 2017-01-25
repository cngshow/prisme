module TerminologyConfig

  class << self
    attr_accessor :terminology_config #TerminologyConfig.xml (Validated against TerminologyConfig.xsd)
    attr_accessor :terminology_config_errors #TerminologyConfig.xml (Validated against TerminologyConfig.xsd).  Nil if all is good
  end

  def self.parse_terminology_config
    return TerminologyConfig.terminology_config unless TerminologyConfig.terminology_config.nil?
    persistent_terminology_file_root = "#{$PROPS['PRISME.data_directory']}/TerminologyConfig"
    term_file_root = './config/tds/TerminologyConfig'
    term_xml = File.exists?(persistent_terminology_file_root+'.xml') ? persistent_terminology_file_root + '.xml' : term_file_root + '.xml'
    term_xsd = File.exists?(persistent_terminology_file_root+'.xsd') ? persistent_terminology_file_root + '.xsd' : term_file_root + '.xsd'
    xsd = Nokogiri::XML::Schema(File.read(term_xsd))
    doc = Nokogiri::XML(File.read(term_xml))
    errors = []
    xsd.validate(doc).each do |error|
      $log.error("TerminologyConfig error  #{error.message}")
      errors << error
    end
    TerminologyConfig::terminology_config_errors = errors
    raise TerminologyConfigParseError.new(errors) unless errors.empty?
    ## continue on to build data structure...
    $log.info("TerminologyConfig passes xsd validation!")
    #  PrismeUtilities::terminology_config = ??  # meet with Randy
    h =  Hash.from_xml(doc.to_s)
    File.open('./tmp/terminology_config.yml','w') do |f| f.write h.to_yaml end
    TerminologyConfig.terminology_config = HashWithIndifferentAccess.new h
    TerminologyConfig.terminology_config
  end

  def self.terminology_domains
    r_val = parse_terminology_config[:Terminology][:Domains][:Domain].deep_dup
    r_val = [r_val] unless r_val.is_a? Array
    arrayitize_subsets r_val
    r_val
  end

  #all non active subsets filtered out
  def self.terminology_domains_active
    domains = terminology_domains
    domains.each do |domain|
      active_subsets = domain[:Subset].reject do |subset|
        !boolean(subset[:Active]) #reject if inactive
      end
      domain[:Subset] = active_subsets
    end
    domains
  end

  def self.terminology_domains_inactive
    domains = terminology_domains
    domains.each do |domain|
      inactive_subsets = domain[:Subset].reject do |subset|
        boolean(subset[:Active]) #reject if active
      end
      domain[:Subset] = inactive_subsets
    end
    domains
  end

  #returns a HashWithIndifferentAccess where each key is the name, like 'Allergy' and the value is an array of subset names
  #sample:
# {"Allergy"=>["Reactions", "Reactants"], "Immunizations"=>["Immunization Procedure", "Skin Test"], "National Drug File"=>[], "Pharmacy"=>["Medication Routes"], "Orders"=>["Order Status", "Nature of Order"], "TIU"=>["TIU Status"
# , "TIU Doctype", "TIU Role", "TIU SMD", "TIU Service", "TIU Setting", "TIU Titles"], "Vitals"=>["Vital Types", "Vital Categories", "Vital Qualifiers"]}
  def self.subset_gui
    @@subset_gui ||= HashWithIndifferentAccess.new
    return @@subset_gui.deep_dup unless @@subset_gui.empty?
    terminology_domains_active.each do |domain|
      @@subset_gui[domain[:Name]] ||= []
      domain[:Subset].each do |subset|
        @@subset_gui[domain[:Name]] << subset[:Name]
      end
    end
    @@subset_gui.deep_dup
  end

  class TerminologyConfigParseError < StandardError
    def initialize(errors)
      @errors = errors
    end

    attr_reader :errors
  end

  private
  # <Properties>
  #    <Property>
  #        <Name>Search_Term</Name>
  # 				<AllowEmpty>true</AllowEmpty>
  #         <IsList>true</IsList>
  # 	</Property>
  #	</Properties>

  #Consider the xml above.  Since there is only one property it will resolve to hash. If there had been more than one it would have
  #resolved to an array of hashes.  I would rather have an array of length 1 hence the 'arrayitize' methods below
  def self.arrayitize_subsets(domains)
    domains.each do |d|
      d[:Subset] = [d[:Subset]] if d[:Subset].is_a? Hash
    end
    domains
  end

end
# load('./lib/utilities/xml_utilities.rb')

