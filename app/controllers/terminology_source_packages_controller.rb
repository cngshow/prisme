class TerminologySourcePackagesController < ApplicationController
  before_action :auth_registered

  def new
    @package = TerminologySourcePackage.new
    2.times { @package.terminology_source_contents.build }
  end

  # POST /terminology_package
  # POST /terminology_package.json
  def create
    @package = TerminologySourcePackage.new(terminology_source_package_params)
    @package.user = current_user.email

    respond_to do |format|
      if @package.save
        upload(@package)
        format.html { redirect_to @package, notice: 'Isaac database was successfully created.' }
        format.json { render :show, status: :created, location: @package }
      else
        format.html { render :new }
        format.json { render json: @package.errors, status: :unprocessable_entity }
      end
    end
  end

  private


  def upload(package)
    id = package.id
    # pull out the git authentication information
    git_props = Service.get_git_props
    git_url = git_props[PrismeService::GIT_REPOSITORY_URL]
    git_user = git_props[PrismeService::GIT_USER]
    git_pass = git_props[PrismeService::GIT_PWD]
    artifactopry_props = Service.get_artifactory_props
    repository_url =  artifactopry_props[PrismeService::NEXUS_REPOSITORY_URL]
    repository_username = artifactopry_props[PrismeService::NEXUS_USER]
    repository_password = artifactopry_props[PrismeService::NEXUS_PWD]
    files = []
    file_root = Rails.root.to_s + TerminologySourceContent::ROOT_PATH
    # package = TerminologySourcePackage.all.last
    package.terminology_source_contents.each do |uploaded_file|
      files << file_root + uploaded_file.id.to_s + '/' + uploaded_file.upload_file_name
    end

    begin
      task = IsaacUploader::create_src_upload_configuration(supported_converter_type: IsaacUploader::SCT_EXTENSION, version: "50.6",
                                                            extension_name: "us",
                                                            files_to_upload: files ,git_url: git_url,
                                                            git_username: git_user, git_password: git_pass,
                                                            artifact_repository_url: repository_url, repository_username:repository_username,
                                                            repository_password: repository_password)
      progress_observer = IsaacUploader::UploadObserver.new()
      state_observer = IsaacUploader::StateObserver.new()
      title_observer = IsaacUploader::UploadObserver.new()
      task.progressProperty.addListener(progress_observer)
      task.stateProperty.addListener(state_observer)
      task.titleProperty.addListener(title_observer)
      IsaacUploader::TaskHolder.instance.put(id, {task: task, progress_observer: progress_observer, state_observer: state_observer, title_observer: title_observer})

      #kick off the job
      TerminologyUploadTracker.perform_later(package, files)
    rescue IsaacUploader::UploadException => ex
      #log and redirect
      $log.error {"Upload exception! " + ex.to_s}
      #redirect and flash error....
      #consider destroying the package
      #package.destroy
    end
  end
  # Never trust parameters from the scary internet, only allow the white list through.
  def terminology_source_package_params
    params.require(:terminology_source_package).permit(:user, terminology_source_contents_attributes: [ :upload ])
  end

end
