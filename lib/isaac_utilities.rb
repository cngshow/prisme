module JIsaacLibrary
  include_package 'gov.vha.isaac.ochre.pombuilder.artifacts'#IBDFFile, SDOSourceContent, Converter, Artifact
  include_package 'gov.vha.isaac.ochre.pombuilder.dbbuilder'#DBConfigurationCreator
  include_package 'gov.vha.isaac.ochre.pombuilder.converter'#ContentConverterCreator, SupportedConverterTypes, UploadFileInfo, SrcUploadCreator
  include_package 'gov.vha.isaac.ochre.pombuilder.upload'#UploadFileInfo, SrcUploadCreator
  include_package 'gov.vha.isaac.ochre.api.util'#WorkExecutors

    #invoke as follows:
  #ibdf_file_to_j_a(["org.foo","loinc","5.0"],["org.foo","loinc","3.0","some_classifier"],...)
    #JIsaacLibrary::ibdf_file_to_j_a(["org.foo","loinc","5.0"],["org.foo","loinc","3.0","some_classifier"])
    #JIsaacLibrary::ibdf_file_to_j_a([]) #for no additional args
  def self.ibdf_file_to_j_a(*args)
    build_a(args,IBDFFile)
  end

  def self.create_ibdf_sdo_java_array(*args)
    clazz_string = args.pop
    array = []
    args.each do |hash|
      array << [hash[:group_id], hash[:artifact], hash[:version], hash[:classifier]] if hash[:classifier]
      array << [hash[:group_id], hash[:artifact], hash[:version]] unless hash[:classifier]
    end
    build_a(array, const_get(clazz_string))
  end

    #JIsaacLibrary::sdo_source_content_to_j_a(["org.foo","loinc","5.0"],["org.foo","loinc","3.0","some_classifier"])
  def self.sdo_source_content_to_j_a(*args)
    build_a(args,SDOSourceContent)
  end

 # JIsaacGit::get_sdo(group_id:source_term, artifact: s_artifact, version: s_version)
  def self.get_sdo(group_id:, artifact:, version:, classifier: nil)
    build(group_id: group_id, artifact: artifact, version: version, classifier: classifier, clazz: SDOSourceContent)
  end

  # JIsaacGit::get_ibdf(group_id:converted_term, artifact: c_artifact, version: c_version, classifier: c_classifier)
  def self.get_ibdf
    build(group_id: group_id, artifact: artifact, version: version, classifier: classifier, clazz: IBDFFile)
  end

  private

  def self.build(group_id:, artifact:, version:, classifier: nil, clazz:)
    return clazz.new(group_id, artifact, version) if classifier.nil?
    clazz.new(group_id, artifact, version, classifier)
  end

  def self.build_a(args,clazz)
    a = []
    return [].to_java(clazz) if args.length == 0
    args.each do |e|
      raise 'Invalid argument length' unless ((e.length == 3) || (e.length == 4))
      type = clazz.new(e[0],e[1],e[2]) if e.length == 3
      type = clazz.new(e[0],e[1],e[2],e[3]) if e.length == 4
      a << type
    end
    a.to_java(clazz)
  end
  class GitFailureException < StandardError
  end
end

module IsaacUploader
  #Conveniance constants
  LOINC = JIsaacLibrary::SupportedConverterTypes::LOINC
  LOINC_TECH_PREVIEW = JIsaacLibrary::SupportedConverterTypes::LOINC_TECH_PREVIEW
  SCT = JIsaacLibrary::SupportedConverterTypes::SCT
  SCT_EXTENSION = JIsaacLibrary::SupportedConverterTypes::SCT_EXTENSION
  VHAT = JIsaacLibrary::SupportedConverterTypes::VHAT
  RXNORM = JIsaacLibrary::SupportedConverterTypes::RXNORM
  RXNORM_SOLOR = JIsaacLibrary::SupportedConverterTypes::RXNORM_SOLOR
  ALL_SUPPORTED_CONVERTER_TYPES = [LOINC,LOINC_TECH_PREVIEW, SCT, SCT_EXTENSION, VHAT, RXNORM, RXNORM_SOLOR]
  CONVERTER_TYPE_GUI_HASH = {}
  ALL_SUPPORTED_CONVERTER_TYPES.each do |converter|
    CONVERTER_TYPE_GUI_HASH[converter] ||= {}
    CONVERTER_TYPE_GUI_HASH[converter][:artifact_dependencies] = converter.getArtifactDependencies.map do |e| e.to_s end
    CONVERTER_TYPE_GUI_HASH[converter][:ibdf_dependencies] = converter.getIBDFDependencies.map do |e| e.to_s end
    CONVERTER_TYPE_GUI_HASH[converter][:artifact_id] = converter.getArtifactId.to_s
    CONVERTER_TYPE_GUI_HASH[converter][:upload_file_info] ||= []
    converter.getUploadFileInfo.each do |uf|
      hash = {}
      hash[:suggested_source_location] = uf.getSuggestedSourceLocation.to_s
      hash[:suggested_source_url] = uf.getSuggestedSourceURL.to_s
      hash[:expected_naming_pattern] = uf.getExpectedNamingPatternDescription.to_s
      hash[:expected_name_regex] = uf.getExpectedNamingPatternRegExpPattern.to_s
      hash[:sample_name] = uf.getSampleName.to_s
      hash[:file_required] = uf.fileIsRequired
      CONVERTER_TYPE_GUI_HASH[converter][:upload_file_info] << hash
    end
  end

  def self.create_src_upload_configuration (supported_converter_type:, version:, extension_name:, files_to_upload:,
      git_url:, git_username:, git_password:,  artifact_repository_url:, repository_username:, repository_password:)
    files_to_upload = files_to_upload.map do |file_as_string| java.io.File.new(file_as_string) end
    begin
      return JIsaacLibrary::SrcUploadCreator.createSrcUploadConfiguration(supported_converter_type, version, extension_name, files_to_upload, git_url, git_username, git_password, artifact_repository_url, repository_username, repository_password)
    rescue java.lang.Throwable => ex
      $log.error("Failed to upload files! " + ex.to_s)
      raise UploadException.new(ex)
    end
  end

  def self.start_work(task: )
    JIsaacLibrary::WorkExecutors.safeExecute(task)
  end

  class UploadObserver
    include javafx.beans.value.ChangeListener
    attr_reader :old_value, :new_value
    def changed(observable_task, oldValue, newValue)
      $log.debug{"#{observable_task}:: oldValue = #{oldValue}, newValue = #{newValue}"}
      @old_value = oldValue
      @new_value = newValue
    end
  end

  class StateObserver < UploadObserver
    attr_reader :last_event_time
    def changed(observable_task, oldValue, newValue)
      super observable_task, oldValue, newValue
      @last_event_time = Time.now
    end
  end

  class TaskHolder
    include Singleton

    def put(k,v)
      @job_map[k] = v
    end

    def get(k)
      @job_map[k]
      #if above is nil, find job leaf with this ID and get state.
    end

    def current_progress(terminology_package_id:)
      h = get(terminology_package_id)
      progress = nil
      if (h.nil?)
        ar = fetch_leaf terminology_package_id
        progress = TerminologyUploadTracker.progress ar
        state = TerminologyUploadTracker.state ar
        done = ((TerminologyUploadTracker.done? state) || (PrismeJob.orphan? ar))
        $log.error("I am expecting to always be done if I am pulling data from the job active record! Done is #{done}") unless done
        $log.debug("Progress (from the DB) is #{progress}")
        progress = 1 if done
      else
        progress = h[:progress_observer].new_value
        state = h[:state_observer].new_value
        done = TerminologyUploadTracker.done? state
        $log.debug("Progress (from the Observer) is #{progress}")
        progress = 1 if done
      end
      progress
    end


    def current_state(terminology_package_id:)
      h = get(terminology_package_id)
      state = nil
      if (h.nil?)
        ar = fetch_leaf terminology_package_id
        state = TerminologyUploadTracker.state ar
        state = PrismeJobConstants::Status::STATUS_HASH[:ORPHANED] if PrismeJob.orphan? ar
        $log.debug("State (from the DB) is #{state}")
      else
        state = h[:state_observer].new_value
        $log.debug("State (from the Observer) is #{state}")
      end
      state
    end

    def title(terminology_package_id:)
      h = get(terminology_package_id)
      title = nil
      if (h.nil?)
        ar = fetch_leaf terminology_package_id
        title = TerminologyUploadTracker.title ar
        $log.debug("Title (from the DB) is #{title}")
      else
        title = h[:title_observer].new_value
        $log.debug("Title (from the Observer) is #{title}")
      end
      title
    end

    def finished_time(terminology_package_id:)
      h = get(terminology_package_id)
      time = Time.now
      if (h.nil?)
        ar = fetch_leaf terminology_package_id
        time = Time.at((TerminologyUploadTracker.finish_time ar).to_i)
        $log.debug("Time (from the DB) is #{time}")
      else
        #Are we done?  Use the final event time!!
        state_obs = h[:state_observer]
        time = state_obs.last_event_time if TerminologyUploadTracker.done? state_obs.new_value
        $log.debug("Time is Time.now or the final time...")
      end
      time
    end

    def current_result(terminology_package_id:)
      h = get(terminology_package_id)
      result = nil
      if (h.nil?)
        ar = fetch_leaf terminology_package_id
        result = ar.result
        result = "Server reboot during upload." if PrismeJob.orphan? ar
        $log.debug("Result (from the DB) is #{result}")
      else
        result = "Uploading..."
        state = h[:state_observer].new_value
        done = TerminologyUploadTracker.done? state
        result = "Finished..." if done
        $log.debug("Result (from the Observer) is #{result}")
      end
      result
    end

    def delete(k)
      @job_map.delete(k)
    end

# IsaacUploader::TaskHolder.instance.current_progress 377
# load './lib/isaac_utilities.rb'
    private
    def fetch_leaf(terminology_package_id)
      upload_jobs = PrismeJob.job_name('TerminologyUploadTracker').completed_by(3.days.ago).leaves
      upload_jobs = upload_jobs.select do |j|  terminology_package_id.to_s.eql?(TerminologyUploadTracker.package_id(j).to_s) end
      $log.error ("I expect only 1 upload job! I got #{upload_jobs.length}") if (upload_jobs.length > 1)
      upload_jobs.first
    end

    def initialize
      @job_map ||= {}
    end
  end

  class UploadException < StandardError
  end
end

module IsaacConverter

  class ConverterArtifact < JIsaacLibrary::Converter
    attr_reader :group_id, :artifact_id, :version
    def initialize(group_id:, artifact_id:, version:)
      super(group_id, artifact_id, version)
      @group_id = group_id
      @artifact_id = artifact_id
      @version = version
    end
  end

  def self.get_converter_options(converter:, repository_url:, repository_username:, repository_password:)
    JIsaacLibrary::ContentConverterCreator.getConverterOptions(converter, repository_url, repository_username, repository_password)
  end

  def self.create_content_converter(sdo_source_content:, converter_version:, additional_source_dependencies_sdo_j_a:, additional_source_dependencies_ibdf_j_a:,converter_option_values:, git_url:,git_user:, git_pass:)
    hash = {}
    converter_option_values.each_pair do |k,v|
      hash[k] = java.util.HashSet.new(v)
    end
    JIsaacLibrary::ContentConverterCreator.createContentConverter(sdo_source_content, converter_version, additional_source_dependencies_sdo_j_a, additional_source_dependencies_ibdf_j_a, hash, git_url, git_user, git_pass)
  end

  # a = IsaacConverter::get_converter_for_source_artifact(artifactId: "vhat-src-data")
  #a.artifact_id | a.group_id | a.artifact_id | a.version |a.classifier | a.has_classifier?
  def self.get_converter_for_source_artifact(artifactId:)
    JIsaacLibrary::ContentConverterCreator.getConverterForSourceArtifact(artifactId)
  end

#  [#<struct type="LOINC", artifact_dependency="", ibdf_dependency="">, #<struct type="LOINC_TECH_PREVIEW", artifact_dependency="loinc-src-data", ibdf_dependency="rf2-ibdf-sct">, #<struct type="SCT", artifact_dependency="", ibd
 #a.length     f_dependency="">, #<struct type="SCT_EXTENSION", artifact_dependency="", ibdf_dependency="rf2-ibdf-sct">, #<struct type="VHAT", artifact_dependency="", ibdf_dependency="">]
  def self.get_supported_conversions
    converterType = Struct.new(:type,:artifact_id,:artifact_dependency, :ibdf_dependency)
    r_val = []
    JIsaacLibrary::ContentConverterCreator.getSupportedConversions.map do |supportedConverterType|
      #CHDR, if CHDR was real, may motivate the replacement of the call to 'first' to be replaced with the actual arrays
      r_val << converterType.new(supportedConverterType.to_s,supportedConverterType.getArtifactId.to_s, supportedConverterType.getArtifactDependencies.first.to_s, supportedConverterType.getIBDFDependencies.first.to_s)
      #When chdr comes use this.
      #r_val << converterType.new(supportedConverterType.to_s, supportedConverterType.getArtifactDependencies.map(&:to_s), supportedConverterType.getIBDFDependencies.map(&:to_s))
    end
    r_val
  end

  def self.get_supported_conversion(artifact_id:)
    get_supported_conversions.each do |converterType|
      if(artifact_id.eql? converterType.artifact_id)
        return converterType
      elsif (artifact_id =~ /^rf2-src-data-.*-extension$/ && converterType.artifact_id.eql?("rf2-src-data-*-extension"))
        return converterType
      end
    end
    nil
  end

end

=begin
load('./lib/isaac_git_utilities.rb')
source_term = "gov.vha.isaac.terminology.source.rf2"
s_artifact = "rf2-src-data-us-extension"
s_version = "20150301"
#sdo_j_a = JIsaacGit::sdo_source_content_to_j_a([source_term, s_artifact, s_version]) #sdo_source_content
sdo_source_content =  JIsaacGit::get_sdo(group_id:source_term, artifact:s_artifact, version:s_version)
converter_version = "3.1-SNAPSHOT" #no f*ing clue how to get this
additional_source_dependencies =  JIsaacGit::sdo_source_content_to_j_a()# for nothing additional
converted_term = "gov.vha.isaac.terminology.converted"
c_artifact = "rf2-ibdf-sct"
c_version = "20150731-loader-3.1-SNAPSHOT"
c_classifier = "Snapshot"

git_url = "https://github.com/VA-CTT/db_tests.git"
git_user =  "cshupp1"
git_pass = "NA"

ibdf_a = JIsaacGit::ibdf_file_to_j_a([converted_term,c_artifact,c_version])
ibdf_a = JIsaacGit::ibdf_file_to_j_a([converted_term,c_artifact,c_version], [source_term,s_artifact,s_version])
ibdf_a = JIsaacGit::create_ibdf_sdo_java_array({group_id: converted_term,artifact: c_artifact,version: c_version},"IBDFFile") #last param can be "SDOSourceContent"
ibdf_a = JIsaacGit::create_ibdf_sdo_java_array({group_id: converted_term,artifact: c_artifact,version: c_version},{group_id: source_term,artifact: s_artifact,version: s_version}, "IBDFFile")

tag = IsaacConverter::create_content_converter(sdo_source_content: sdo_source_content, converter_version: converter_version,  additional_source_dependencies_sdo_j_a: additional_source_dependencies, additional_source_dependencies_ibdf_j_a: ibdf_a, git_url: git_url, git_user: git_user, git_pass: git_pass)
=end


# class Artifact
#   attr_reader :group_id, :artifact_id, :version, :classifier
#   def initialize(group_id:, artifact_id:, version:, classifier: nil)
#     group_id = group_id
#     artifact_id = artifact_id
#     version = version
#     classifier = classifier
#     raise "group id missing!" if group_id.nil?
#     raise "artifact id missing!" if artifact_id.nil?
#     raise "version missing!" if version.nil?
#   end
# end
#
# class IBDFFile < Artifact
# end
#
# class SDOSourceContent < Artifact
# end
# group_id = gov.vha.isaac.terminology.converters
# artifact_id = loinc-mojo
# version = 5.3-SNAPSHOT|