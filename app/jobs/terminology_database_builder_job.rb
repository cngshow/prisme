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
    result_hash = {}
    result_hash[:db_name] = db_name
    result_hash[:db_version] = db_version
    result_hash[:db_description] = db_description
    result_hash[:artifact_classifier] = artifact_classifier
    result_hash[:classify] = classify
    result_hash[:ibdf_files] = ibdf_files
    result_hash[:metadata_version] = metadata_version
    result = ''
    begin
      $log.debug("About to create a DB CONFIG.")
      result = IsaacDBConfigurationCreator::create_db_configuration(name: db_name, version: db_version, description: db_description,
                                                                    result_classifier: artifact_classifier, classify_bool: classify,
                                                                    ibdf_files: ibdf_files, metadata_version: metadata_version,
                                                                    git_url: git_url, git_user: git_user, git_password: git_pass)
      $log.debug("DB CONFIG=#{result}")
    rescue => ex
      result = ex.message
      $log.error("DB CONFIG failed. #{ex}")
      raise ex
    ensure
      save_result(result, result_hash)
    end

  end

  def self.db_name(ar)
    result = ''
    result << result_hash(ar)[:db_name.to_s].to_s
  end

  def self.db_version(ar)
    result = ''
    result << result_hash(ar)[:db_version.to_s].to_s
  end

  def self.db_description(ar)
    result = ''
    result << result_hash(ar)[:db_description.to_s].to_s
  end

  def self.artifact_classifier(ar)
    result = ''
    result << result_hash(ar)[:artifact_classifier.to_s].to_s
  end

  def self.classify(ar)
    result = ''
    result << result_hash(ar)[:classify.to_s].to_s
  end

  def self.ibdf_files(ar)
    result = result_hash(ar)[:ibdf_files.to_s]
    result = [] if result.nil?
    result
  end

  def self.metadata_version(ar)
    result = ''
    result << result_hash(ar)[:metadata_version.to_s].to_s
  end

end