class TerminologyDatabaseBuilder < PrismeBaseJob

  def perform(*args)
    db_name = args.shift
    db_version = args.shift
    db_description = args.shift
    artifact_classifier = args.shift
    classify = args.shift
    ibdf_files = args.shift
    metadata_version = args.shift

    # pull out the git authentication information
    git_props = Service.get_git_props
    git_url = git_props[PrismeService::GIT_REPOSITORY_URL]
    git_user = git_props[PrismeService::GIT_USER]
    git_pass = git_props[PrismeService::GIT_PWD]
    #result_hash = nil
    result = ''
    begin
      result =  IsaacDBConfigurationCreator::create_db_configuration(name: db_name, version: db_version, description: db_description,
                                                                     result_classifier: artifact_classifier, classify_bool: classify,
                                                                     ibdf_files: ibdf_files, metadata_version: metadata_version,
                                                                     git_url: git_url, git_user: git_user, git_password: git_pass )
    rescue => ex
        result = ex.message
        raise ex
    ensure
      save_result(result)
    end

end

end