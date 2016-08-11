class TerminologySourcePackagesController < ApplicationController
  before_action :auth_registered

  def index
    # new up a TerminologySourcePackage model for the modal popup allowing the user to create a new package
    @package = TerminologySourcePackage.new
  end

  # POST /terminology_package
  # POST /terminology_package.json
  def create
    @package = TerminologySourcePackage.new(terminology_source_package_params)
    @package.user = prisme_user.user_name
    success = @package.save
    upload(@package)

    # save flash?
    redirect_to action: :index
  end

  # ajax calls
  def ajax_load_build_data
    row_limit = params[:row_limit]
    # get the root tracker jobs
    data = PrismeJob.job_name('TerminologyUploadTracker')
               .where('root_job_id is null').orphan(false)
               .completed_by(($PROPS['PRISME.job_queue_trim'].to_i).days.ago)
               .order(completed_at: :desc)
               .limit(row_limit)
    ret = []

    data.each do |jsb|
      package_id = TerminologyUploadTracker.package_id(jsb)
      next if package_id.nil?

      # pull the row as json
      row_data = JSON.parse(jsb.to_json)
      row_data['started_at'] = row_data['started_at'].nil? ? nil : DateTime.parse(row_data['started_at']).to_time.to_i
      # strip out just the file name(s) being uploaded
      row_data['uploaded_files'] = TerminologyUploadTracker.uploaded_files(jsb).map { |f| f.reverse.split('/')[0].reverse }.join(', ')
      # get the current state/progress of this job
      progress = IsaacUploader::TaskHolder.instance.current_progress(terminology_package_id: package_id)
      state = IsaacUploader::TaskHolder.instance.current_state(terminology_package_id: package_id)
      result = IsaacUploader::TaskHolder.instance.current_result(terminology_package_id: package_id)
      state_time = IsaacUploader::TaskHolder.instance.finished_time(terminology_package_id: package_id)
      title = IsaacUploader::TaskHolder.instance.title(terminology_package_id: package_id)
      row_data['state'] = state.nil? ? jsb.status.to_s : state.to_s
      row_data['state_time'] = state_time.to_i
      row_data['title'] = title.to_s
      row_data['user'] = TerminologyUploadTracker.user(jsb).to_s
      row_data['result'] = result.to_s
      row_data['progress'] = progress.nil? ? 0 : (progress.to_f * 100).round

      if (!row_data['started_at'].nil?)
        row_data[:elapsed_time] = ApplicationHelper.convert_seconds_to_time(row_data['state_time'] - row_data['started_at'])
      else
        row_data[:elapsed_time] = ''
      end

      ret << row_data
    end

    render json: ret
  end

  def ajax_check_polling
    prisme_job_has_running_jobs = PrismeJob.has_running_jobs?('TerminologyUploadTracker')
    render json: {poll: prisme_job_has_running_jobs}
  end

  def ajax_converter_change
    converter = params[:converter]
    a = IsaacUploader::CONVERTER_TYPE_GUI_HASH
    upload_options = a.select { |i| i.to_s.eql?(converter) }
    render json: upload_options.first[1]
  end

  private
  def upload(package)
    terminology_package_id = package.id
    # pull out the git authentication information
    git_props = Service.get_git_props
    git_url = git_props[PrismeService::GIT_REPOSITORY_URL]
    git_user = git_props[PrismeService::GIT_USER]
    git_pass = git_props[PrismeService::GIT_PWD]
    artifactory_props = Service.get_artifactory_props
    repository_url = artifactory_props[PrismeService::NEXUS_PUBLICATION_URL]
    repository_username = artifactory_props[PrismeService::NEXUS_USER]
    repository_password = artifactory_props[PrismeService::NEXUS_PWD]
    files = []
    file_root = Rails.root.to_s + TerminologySourceContent::ROOT_PATH

    package.terminology_source_contents.each do |uploaded_file|
      files << file_root + uploaded_file.id.to_s + '/' + uploaded_file.upload_file_name
    end

    begin
      task = IsaacUploader::create_src_upload_configuration(supported_converter_type: params['supported_converter'],
                                                            version: params['version'],
                                                            extension_name: params['extension_name'],
                                                            files_to_upload: files,
                                                            git_url: git_url,
                                                            git_username: git_user,
                                                            git_password: git_pass,
                                                            artifact_repository_url: repository_url,
                                                            repository_username: repository_username,
                                                            repository_password: repository_password)
      progress_observer = IsaacUploader::UploadObserver.new
      state_observer = IsaacUploader::StateObserver.new
      title_observer = IsaacUploader::UploadObserver.new
      task.progressProperty.addListener(progress_observer)
      task.stateProperty.addListener(state_observer)
      task.titleProperty.addListener(title_observer)
      IsaacUploader::TaskHolder.instance.put(terminology_package_id, {task: task, progress_observer: progress_observer, state_observer: state_observer, title_observer: title_observer})

      #kick off the job
      TerminologyUploadTracker.perform_later(package, files)
    rescue IsaacUploader::UploadException => ex
      #log and redirect
      $log.error { "Upload exception! #{ex.to_s}" }
      #redirect and flash error....
      #consider destroying the package
      #package.destroy
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def terminology_source_package_params
    params.require(:terminology_source_package).permit(:user, terminology_source_contents_attributes: [:upload])
  end

end
