class TerminologyUploadTracker < PrismeBaseJob

  def perform(*args)
    package_ar = args.shift
    start_work = args.shift
    task_hash = IsaacUploader::TaskHolder.instance.get(package_ar.id)
    task = task_hash[:task]
    progress_observer = task_hash[:progress_observer]
    state_observer = task_hash[:state_observer]
    result_hash = {}
    package_id = package_ar.id
    result_hash[:package_id] = package_id
    result_hash[:progress] = progress_observer.new_value.to_s
    result_hash[:state] = state_observer.new_value.to_s
    result = result_hash[:state]
    begin
      IsaacUploader.start_work(task: task) if start_work
      state  = state_observer.new_value
      $log.info("The current upload for user #{package_ar.user} is #{progress_observer.new_value}, The current state is #{state_observer.new_value}")
      if ((state == javafx.concurrent.Worker::State::SUCCEEDED) || (state == javafx.concurrent.Worker::State::CANCELLED) || (state == javafx.concurrent.Worker::State::FAILED))
        $log.info("Deleting the files!  We are done!  Finished in state #{state}")
        result = state.to_s
        #result = task.to_s
        $log.debug("Task is #{task}")
        package_ar.destroy
        IsaacUploader::TaskHolder.instance.delete(package_id)
      else
        TerminologyUploadTracker.set(wait_until: $PROPS['TERMINOLOGY_UPLOAD.upload_check'].to_i.seconds.from_now).perform_later(package_ar, false, track_child_job)
      end
    rescue => ex
        $log.error("Failed to complete terminology upload tracking! #{ex}")
        result = ex.to_s
    ensure
      save_result(result, result_hash)
    end

  end

  def self.state(ar)
    result_hash(ar)[:state.to_s]
  end

  def self.progress(ar)
    result_hash(ar)[:progress.to_s]
  end

  def self.package_id(ar)
    result_hash(ar)[:package_id.to_s]
  end
end
