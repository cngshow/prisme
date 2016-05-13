require 'zip'
require 'digest'
require './app/controllers/concerns/nexus_concern'

java_import 'de.schlichtherle.truezip.file.TFile' do |p,c|
  'JTFile'
end

java_import 'de.schlichtherle.truezip.file.TFileWriter' do |p,c|
  'JTFileWriter'
end

java_import 'de.schlichtherle.truezip.file.TVFS' do |p,c|
  'JTVFS'
end


class ArtifactDownloadJob < PrismeBaseJob
  include NexusConcern

  # rescue_from(ActiveRecord::RecordNotFound) do |exception|
  #   # do something with the exception
  # end

  def cookie_war(war_path, cookie_file, hash)
    $log.info("Adding cookie info to war file #{war_path} into file #{cookie_file}")
    $log.info("Cookie data is " + hash.inspect)
    Zip::File.open(war_path) do |zip|
      zip.get_output_stream(cookie_file) do |file_handle|
        file_handle.puts(hash.keys.map do |e|
          "#{e}=#{hash[e]}"
        end.join("\n"))
      end
    end
  end

  def cookie_war_true_zip(war_path, cookie_file, hash)
    $log.info("Adding cookie info to war file #{war_path} into file #{cookie_file}")
    $log.info("Cookie data is " + hash.inspect)
    path = war_path + '/' + cookie_file
    begin
      entry = JTFile.new(path)
      writer = JTFileWriter.new(entry)
      props = ''
      hash.each_pair do |k,v|
        props << "#{k}=#{v}\n"
      end
      writer.write(props)
    ensure
      writer.close unless writer.nil?
      JTVFS.umount
    end
  end

  def perform(*args)
    begin
      nexus_props = Service.get_artifactory_props
      baseurl = nexus_props[PrismeService::NEXUS_ROOT] + $PROPS['ENDPOINT.nexus_maven_content']
      nexus_query_params = args.shift
      war_cookie_params = args.shift
      war_name = args.shift
      tomcat_ar = args.shift
      warurl = "#{baseurl}?#{nexus_query_params.to_query}"

      result = String.new
      result << "Downloading from URL #{warurl}.\n"
      result << "Fetching war #{war_name}.\n"
      $log.debug("This job is doing URL #{warurl}.")
      $log.debug("This job is doing war #{war_name}.")
      response = get_nexus_connection('*/*').get(warurl, {})
      file_name = "#{Rails.root}/tmp/#{war_name}"
      File.open(file_name, 'wb') { |fp| fp.write(response.body) }
      $log.debug("The file #{war_name} has completed the download!")
      # read and log the sha1 and md5 files associated with this download
      p_clone = nexus_query_params.clone
      p_clone[:p] = nexus_query_params[:p] + '.sha1'
      sha1url = "#{baseurl}?#{p_clone.to_query}"
      sha1 = get_nexus_connection('*/*').get("#{sha1url}", {}).body

      p_clone[:p] = nexus_query_params[:p] + '.md5'
      md5url = "#{baseurl}?#{p_clone.to_query}"
      md5 = get_nexus_connection('*/*').get("#{md5url}", {}).body
      $log.debug('SHA1 for ' + war_name + ' is: ' + sha1)
      $log.debug('MD5 for ' + war_name + ' is: ' + md5)
      #file_name = 'c:/temp/dan.yml'
      actual_sha1 = Digest::SHA1.file(file_name).to_s
      actual_md5 = Digest::MD5.file(file_name).to_s
      $log.debug("Actual SHA1 for #{war_name} is #{actual_sha1}.")
      $log.debug("Actual MD5 for #{war_name} is #{actual_md5}.")
      sha1_match = actual_sha1.eql? sha1
      md5_match = actual_md5.eql? md5
      if (!(sha1_match && md5_match))
        #come here if the file is not a match
        error_msg = ""
        error_msg << "SHA1 mismatch " unless sha1_match
        error_msg << "MD5 mismatch" unless md5_match
        $log.error("Checksum mismatch for #{war_name}. #{error_msg} ")
        raise StandardError, error_msg
      end
      z = nil
      begin
        z = Zip::File.open(file_name)
      rescue => e
        $log.error("#{file_name} is not a valid war file!")
        $log.error(e.backtrace.join("\n"))
        $log.error('Rethrowing: ' + e.message)
        raise e
      end
      context = nil
      begin
        context = z.get_entry('context.txt').get_input_stream.read
        $log.debug('The context root is ' + context)
        result << "The war will be deployed to context root #{context}.\n"
      rescue
        $log.debug('No context.txt file found')
        result << "The war will be deployed to the default context root.\n"
        #not all wars have a context.txt, but if we do we use it
      end
      if (file_name =~ /.*isaac-rest.*/)
        hash = {}
        hash.merge!(war_cookie_params)
        hash.merge!(nexus_props)
        cookie_war_true_zip(file_name, 'WEB-INF/classes/prisme.properties', hash)
        context = "/isaac-rest" #to_do pull this from the database someday.
      else
        #we are Komet!
        cookie_war_true_zip(file_name, 'WEB-INF/config/props/prisme.properties',war_cookie_params)
      end
      $log.debug("Kicking off next job (DeployWar) #{file_name} #{context}")
      #activeRecord instantiate new job
      DeployWarJob.perform_later(file_name, context, tomcat_ar) #, pass in parent id and my ID
    ensure
      save_result result
    end
  end
end
# ArtifactDownloadJob.set(wait_until: 5.seconds.from_now).perform_later
#  include NexusConcern
#job = ArtifactDownloadJob.set(wait_until: 5.years.from_now).perform_later
#job = ArtifactDownloadJob.set(wait_until: 5.years.from_now)
# job.perform_later
#ActiveJobStatus::JobStatus.get_status(job_id: job.job_id)
=begin
ZipFilePath = "./tmp/isaac-rest-1.0.war"
fis = java.io.FileInputStream.new(ZipFilePath)
b = java.io.BufferedInputStream.new fis
zis = java.util.zip.ZipInputStream.new(b)
e =zis.getNextEntry
e= zis.getNextEntry
e = zis.getNextEntry #bombs! Java::JavaUtilZip::ZipException: invalid entry size (expected 1928069120 but got 132 bytes)

fixed in 9 :-(
https://bugs.openjdk.java.net/browse/JDK-8044727

fileOutStream = java.io.FileOutputStream.new(ZipFilePath, true)
zipOutStream = java.util.zip.ZipOutputStream.new(fileOutStream)
fileName = './tmp/foo.txt'
fis = java.io.FileInputStream.new(fileName)
entry = java.util.zip.ZipEntry.new fileName
zipOutStream.putNextEntry(entry)
foo = java.lang.String.new("Foo\nFaa\nFiddle\n").getBytes
zipOutStream.write(foo,0,foo.length)

zipOutStream.closeEntry
zipOutStream.flush
zipOutStream.finishexit
zipOutStream.close
fis.close
fileOutStream.close

java_import 'de.schlichtherle.truezip.file.TFile' do |p,c|
'JTFile'
end

java_import 'de.schlichtherle.truezip.file.TFileWriter' do |p,c|
'JTFileWriter'
end

java_import 'de.schlichtherle.truezip.file.TVFS' do |p,c|
'JTVFS'
end

zipFilePath = "./tmp/isaac-rest-1.0.1.war"
entry = JTFile.new(zipFilePath+'/WEB-INF/classes/foo3.txt')
writer = JTFileWriter.new(entry)
writer.write("This is too hard ****\n")
JTVFS.umount


<dependency>
	<groupId>de.schlichtherle.truezip</groupId>
	<artifactId>truezip</artifactId>
	<version>7.7.9</version>
</dependency>

java_import 'gov.vha.isaac.ochre.pombuilder.artifacts.IBDFFile' do |p,c|
 'Jibdf'
end

java_import 'gov.vha.isaac.ochre.pombuilder.dbbuilder.DBConfigurationCreator' do |p,c|
 'JDBConfigCreator'
end

bdf = Jibdf.new("org.foo","loinc","5.0")
ibdf_array_java = [bdf].to_java(Jibdf)
JDBConfigCreator.createDBConfiguration("test","1.0", "Cris's test database", 'all', true,ibdf_array_java, "4", "https://github.com/VA-CTT/db_tests.git", "cshupp1","ki123alem")

java_import 'gov.vha.isaac.ochre.pombuilder.converter.ContentConverterCreator' do |p,c|
 'JContentConverterCreator'
end
java_import 'gov.vha.isaac.ochre.pombuilder.artifacts.SDOSourceContent' do |p,c|
 'JSDOSourceContent'
end
java_import 'gov.vha.isaac.ochre.pombuilder.artifacts.IBDFFile' do |p,c|
 'Jibdf'
end

source_term = "gov.vha.isaac.terminology.source.rf2"
s_artifact = "rf2-src-data-us-extension"
s_version = "20150301"
sdo_source_content = JSDOSourceContent.new(source_term, s_artifact, s_version)
converter_version = "3.1-SNAPSHOT" #no f*ing clue how to get this
additional_source_dependencies = [].to_java(JSDOSourceContent)
converted_term = "gov.vha.isaac.terminology.converted"
c_artifact = "rf2-ibdf-sct"
c_version = "20150731-loader-3.1-SNAPSHOT"
c_classifier = "Snapshot"
git_url = "https://github.com/VA-CTT/db_tests.git"
git_user =  "cshupp1"
git_pass = "na"

ibdf = Jibdf.new(converted_term, c_artifact, c_version, c_classifier)
ibdf_a = [ibdf].to_java(Jibdf)

JContentConverterCreator.createContentConverter(sdo_source_content, converter_version,  additional_source_dependencies, ibdf_a, git_url, git_user, git_pass)


--end
		ContentConverterCreator.createContentConverter(new SDOSourceContent("gov.vha.isaac.terminology.source.rf2", "rf2-src-data-us-extension", "20150301"),
			"3.1-SNAPSHOT",
			new SDOSourceContent[0],
			new IBDFFile[] {new IBDFFile("gov.vha.isaac.terminology.converted", "rf2-ibdf-sct", "20150731-loader-3.1-SNAPSHOT", "Snapshot")},
				"https://github.com/darmbrust/test.git", "", "");

	public static String createContentConverter(SDOSourceContent sourceContent, String converterVersion, SDOSourceContent[] additionalSourceDependencies,
		IBDFFile[] additionalIBDFDependencies, String gitRepositoryURL, String gitUsername, String gitPassword) throws Exception
	{

	/**
	 * Create a source conversion project which is executable via maven.
	 * @param sourceContent - The artifact information for the content to be converted.  The artifact information must follow known naming conventions - group id should
	 * be gov.vha.isaac.terminology.source.  Currently supported artifactIds are 'loinc-src-data', 'loinc-src-data-tech-preview', 'rf2-src-data-*', 'vhat'
	 * @param converterVersion - The version number of the content converter code to utilize.  The jar file for this converter must be available to the
	 * maven execution environment at the time when the conversion is run.
	 * @param additionalSourceDependencies - Some converters require additional data files to satisfy dependencies. See {@link #getSupportedConversions()}
	 * for accurate dependencies for any given conversion type.
	 * @param additionalIBDFDependencies - Some converters require additional data files to satisfy dependencies. See {@link #getSupportedConversions()}
	 * for accurate dependencies for any given conversion type.
	 * @param gitRepositoryURL - The URL to publish this built project to
	 * @param gitUsername - The username to utilize to publish this project
	 * @param gitPassword - the password to utilize to publish this project
	 * @return the tag created in the repository that carries the created project
	 * @throws Exception
	 */
	public static String createContentConverter(SDOSourceContent sourceContent, String converterVersion, SDOSourceContent[] additionalSourceDependencies,
		IBDFFile[] additionalIBDFDependencies, String gitRepositoryURL, String gitUsername, String gitPassword) throws Exception
	{

SDOSourceContent is the same, classifier is optional
	public IBDFFile(String groupId, String artifactId, String version, String classifier)
	{
		super(groupId, artifactId, version, classifier);
	}

=end