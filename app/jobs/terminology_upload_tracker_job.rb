class TerminologyUploadTracker < PrismeBaseJob

  def perform(*args)
    package_ar = args.shift
    files = args.shift
    task_hash = IsaacUploader::TaskHolder.instance.get(package_ar.id)
    task = task_hash[:task]
    task_result = nil
    progress_observer = task_hash[:progress_observer]
    state_observer = task_hash[:state_observer]
    title_observer = task_hash[:title_observer]
    result_hash = {}
    @package_id = package_ar.id
    result_hash[:package_id] = @package_id
    result_hash[:user] = package_ar.user
    result_hash[:files] = files
    result = result_hash[:state]
    @done = false
    begin
      $log.info("Files: #{files.inspect}")
      if files #start the upload
        IsaacUploader.start_work(task: task)
      else
        $log.debug('About to block and wait for the upload to finish.')
        task_result = nil
        begin
          task_result = IsaacUploader.fetch_result(task: task) #we block and wait
        rescue => ex
          $log.error("The upload failed! #{ex}")
          $log.error(ex.backtrace.join("\n)"))
        end
        state = state_observer.new_value
        unless (task_result.nil? || TerminologyUploadTracker.done?(state))
          state_observer.changed(self, state_observer.new_value, javafx.concurrent.Worker::State::SUCCEEDED)
        end
        $log.info("Blocking call complete.  Result is #{task_result} with a final state of #{state}")
      end
      result_hash[:state] = state.to_s #might be nil
      result_hash[:current_title] = title_observer.new_value.to_s
      result_hash[:progress] = progress_observer.new_value.to_s
      $log.info("The current upload for user #{package_ar.user} is #{progress_observer.new_value}, The current state is #{state_observer.new_value}")
      if TerminologyUploadTracker.done? state
        @done = true
        $log.info("Deleting the files!  We are done!  Finished in state #{state}")
        result = task_result # state.to_s
        #result = task.to_s
        $log.debug("Task is #{task}")
        result_hash[:finish_time] = state_observer.last_event_time.to_i
        package_ar.destroy
      else
        if (files)
          TerminologyUploadTracker.perform_later(package_ar, false, track_child_job)
        end
      end
      progress = IsaacUploader::TaskHolder.instance.current_progress terminology_package_id: @package_id
      state = IsaacUploader::TaskHolder.instance.current_state terminology_package_id: @package_id
      result = IsaacUploader::TaskHolder.instance.current_result terminology_package_id: @package_id
      title = IsaacUploader::TaskHolder.instance.title terminology_package_id: @package_id
      $log.debug("[#{progress}, #{state}, #{title}, #{result}]")
    rescue => ex
      $log.error("Failed to complete terminology upload tracking! #{ex}")
      $log.error(ex.backtrace.join("\n"))
      result = ex.to_s
    ensure
      save_result(result, result_hash)
    end

  end

  def self.title(ar)
    result_hash(ar)[:current_title.to_s]
  end

  def self.finish_time(ar)
    result_hash(ar)[:finish_time.to_s]
  end

  def self.state(ar)
    result_hash(ar)[:state.to_s]
  end

  def self.progress(ar)
    result_hash(ar)[:progress.to_s]
  end

  def self.user(ar)
    result_hash(ar)[:user.to_s]
  end

  def self.uploaded_files(ar)
    result_hash(ar)[:files.to_s]
  end

  def self.package_id(ar)
    result_hash(ar)[:package_id.to_s]
  end

  def self.done?(state)
    ((state.to_s == javafx.concurrent.Worker::State::SUCCEEDED.to_s) || (state.to_s == javafx.concurrent.Worker::State::CANCELLED.to_s) || (state.to_s == javafx.concurrent.Worker::State::FAILED.to_s))
  end

  #called after all metadata related to this job is saved to the database
  def finalize
    if @done
      $log.debug { "Finalize called on #{@package_id}" }
      IsaacUploader::TaskHolder.instance.delete(@package_id) #no memory leaks, no race conditions!
      #this relinquishes all handles to our tasks.  There should be no memory leaks.
    end
  end

end
