class AppDeploymentJob < PrismeBaseJob
  def perform(*args)
    begin
      ArtifactDownloadJob.set(wait: 2.seconds).perform_later(*(args << track_child_job))
    ensure
      result_hash = {}
      result_hash[:message] = "Kicking off application deployment for #{args[2]}"
      save_result "Kicking off application deployment for #{args[2]}", result_hash
    end
  end
end
