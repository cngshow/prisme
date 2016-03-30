require 'zip'
require './app/controllers/concerns/nexus_concern'
class ArtifactDownloadJob < PrismeBaseJob
  include NexusConcern

  @@connection = get_nexus_connection('*/*')
  # rescue_from(ActiveRecord::RecordNotFound) do |exception|
  #   # do something with the exception
  # end

  def perform(*args)
    url = args.shift
    war_name = args.shift
    result = String.new
    result << "Downloading from URL #{url}.\n"
    result << "Fetching war #{war_name}.\n"
    $log.debug("This job is doing URL " + url + ".")
    $log.debug("This job is doing war " + war_name + ".")
    response = @@connection.get(url,{})
    file_name = "./tmp/#{war_name}"
    File.open(file_name, 'wb') { |fp| fp.write(response.body) }
    $log.debug("The file #{war_name} has completed the download!")
    z = Zip::File.open(file_name)
    context = nil
    begin
      context = z.get_entry('context.txt').get_input_stream.read
      $log.debug("The context root is " + context)
      result << "The war will be deployed to context root #{context}.\n"
    rescue
      $log.debug("No context.txt file found")
      result << "The war will be deployed to the default context root.\n"
      #not all wars have a context.txt, but if we do we use it
    end
    $log.debug("Kicking off next job (DeployWar) #{file_name} #{context}")
    #activeRecord instantiate new job
    DeployWarJob.perform_later(file_name,context)#, pass in parent id and my ID
    #DeployWarJob.perform_later()
    active_record = lookup
    active_record.result= result
    active_record.save!
  end

end
# ArtifactDownloadJob.set(wait_until: 5.seconds.from_now).perform_later
#  include NexusConcern
#job = ArtifactDownloadJob.set(wait_until: 5.years.from_now).perform_later
#job = ArtifactDownloadJob.set(wait_until: 5.years.from_now)
# job.perform_later
#ActiveJobStatus::JobStatus.get_status(job_id: job.job_id)
