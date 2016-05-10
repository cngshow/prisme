module JIsaacGit
  include_package 'gov.vha.isaac.ochre.pombuilder.artifacts'#IBDFFile, SDOSourceContent
  include_package 'gov.vha.isaac.ochre.pombuilder.dbbuilder'#DBConfigurationCreator
  include_package 'gov.vha.isaac.ochre.pombuilder.converter'#ContentConverterCreator, SupportedConverterTypes

    #invoke as follows:
  #ibdf_file_to_j_a(["org.foo","loinc","5.0"],["org.foo","loinc","3.0","some_classifier"],...)
  #JIsaacGit::ibdf_file_to_j_a(["org.foo","loinc","5.0"],["org.foo","loinc","3.0","some_classifier"])
  #JIsaacGit::ibdf_file_to_j_a([]) #for no additional args
  def self.ibdf_file_to_j_a(*args)
    build_a(args,IBDFFile)
  end

  def self.create_ibdf_sdo_java_array(*args)
    clazz_string = args.pop
    array = []
    args.each do |hash|
      p hash
      array << [hash[:group_id], hash[:artifact], hash[:version], hash[:classifier]] if hash[:classifier]
      array << [hash[:group_id], hash[:artifact], hash[:version]] unless hash[:classifier]
    end
    build_a(array, const_get(clazz_string))
  end

  #JIsaacGit::sdo_source_content_to_j_a(["org.foo","loinc","5.0"],["org.foo","loinc","3.0","some_classifier"])
  def self.sdo_source_content_to_j_a(*args)
    build_a(args,SDOSourceContent)
  end

 # JIsaacGit::get_sdo(group_id:source_term, artifact: s_artifact, version: s_version)
  def self.get_sdo(group_id:, artifact:, version:, classifier: nil)
    build(group_id: group_id, artifact: artifact, version: version, classifier: classifier, clazz: SDOSourceContent)
  end

  # JIsaacGit::get_sdo(group_id:converted_term, artifact: c_artifact, version: c_version, classifier: c_classifier)
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
      raise "Invalid argument length" unless ((e.length == 3) || (e.length == 4))
      type = clazz.new(e[0],e[1],e[2]) if e.length == 3
      type = clazz.new(e[0],e[1],e[2],e[3]) if e.length == 4
      a << type
    end
    a.to_java(clazz)
  end
  class GitFailureException < StandardError
  end
end

module IsaacConverter

  def self.create_content_converter(sdo_source_content:, converter_version:, additional_source_dependencies_sdo_j_a:, additional_source_dependencies_ibdf_j_a:, git_url:,git_user:, git_pass:)
    JIsaacGit::ContentConverterCreator.createContentConverter(sdo_source_content,converter_version,  additional_source_dependencies_sdo_j_a, additional_source_dependencies_ibdf_j_a, git_url, git_user, git_pass)
  end
end

module IsaacDatabase

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
