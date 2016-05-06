require 'zip'
require 'digest'
require './app/controllers/concerns/nexus_concern'
class ArtifactDownloadJob < PrismeBaseJob
  include NexusConcern

  # rescue_from(ActiveRecord::RecordNotFound) do |exception|
  #   # do something with the exception
  # end

  def cookie_war(war_path,cookie_file, hash)
    $log.info("Adding cookie info to war file #{war_path} into file #{cookie_file}")
    $log.info("Cookie data is " + hash.inspect)
    z = Zip::File.open(war_path)  do |zip|
      zip.get_output_stream(cookie_file) do |file_handle|
        file_handle.puts(hash.keys.map do |e| "#{e}=#{hash[e]}" end.join("\n"))
      end
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
      file_name = "./tmp/#{war_name}"
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
        cookie_war(file_name,'WEB-INF/classes/prisme.properties', hash)
      else
        $log.debug("Not cookie-ing up #{file_name}")
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
