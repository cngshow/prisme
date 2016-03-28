require 'zip'
require './app/controllers/concerns/nexus_concern'
class ArtifactDownloadJob < ActiveJob::Base
  queue_as :default
  include NexusConcern

  @@connection = get_nexus_connection('*/*')
  # rescue_from(ActiveRecord::RecordNotFound) do |exception|
  #   # do something with the exception
  # end

  def perform(*args)
    url = args.shift
    war_name = args.shift
    $log.debug("This job is doing URL " + url)
    $log.debug("This job is doing war " + war_name)
    response = @@connection.get(url,{})
    file_name = "./tmp/#{war_name}"
    File.open(file_name, 'wb') { |fp| fp.write(response.body) }
    $log.debug("The file #{war_name} has completed the download!")
    z = Zip::File.open(file_name)
    context = nil
    begin
      context = z.get_entry('context.txt').get_input_stream.read
      $log.debug("The context root is " + context)
    rescue
      $log.debug("No context.txt file found")
        #not all wars have a context.txt, but if we do we use it
    end
    $log.debug("Next! #{file_name} #{context}")
    #activeRecord instantiate new job
    DeployWarJob.perform_later(file_name,context)#, pass in parent id and my ID
    #DeployWarJob.perform_later()
  end

end
# ArtifactDownloadJob.set(wait_until: 5.seconds.from_now).perform_later
#
