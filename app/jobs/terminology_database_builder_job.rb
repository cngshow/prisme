# require './app/controllers/concerns/nexus_concern'
require './lib/utilities/nexus_utility'

class TerminologyDatabaseBuilder < PrismeBaseJob
  def perform(*args)
    db_name = args.shift
    db_version = args.shift
    db_description = args.shift
    artifact_classifier = args.shift
    classify = args.shift
    ibdf_files = args.shift
    metadata_version = args.shift
    metadata_version = NexusUtility::NexusArtifact.init_from_select_key(metadata_version).v

    # pull out the git authentication information
    git_props = Service.get_git_props
    git_url = git_props[PrismeService::GIT_ROOT]
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
    begin
      tag_name = IsaacDBConfigurationCreator::create_db_configuration(name: db_name, version: db_version, description: db_description,
                                                                    result_classifier: artifact_classifier, classify_bool: classify,
                                                                    ibdf_files: ibdf_files, metadata_version: metadata_version,
                                                                    git_url: git_url, git_user: git_user, git_password: git_pass)
      # these locals are used in erb call below! do not remove!
      development = Rails.env.development?
      git_failure = nil
      # file to render
      props = Service.get_build_server_props
      j_xml = PrismeService::JENKINS_XML
      url = props[PrismeService::JENKINS_ROOT]
      user = props[PrismeService::JENKINS_USER]
      password = props[PrismeService::JENKINS_PWD]

      # nexus url - these variables are in the local binding for the erb - DO NOT REMOVE!
      nexus_props = Service.get_artifactory_props
      nexus_publication_url = nexus_props[PrismeService::NEXUS_PUBLICATION_URL]
      git_content_url = JIsaacLibrary::GitPublish.constructChangesetRepositoryURL git_url #used in PrismeService::JENKINS_XML

      # you MUST pass binding in order to have the erb process local variables
      @job_xml = ERB.new(File.open(j_xml, 'r') { |file| file.read }).result(binding)
      $log.info("The jenkins xml is--")
      $log.info(@job_xml)
      t_s = Time.now.strftime('%Y_%m_%dT%H_%M_%S')
      job = JenkinsStartBuild.perform_later("#{JenkinsStartBuild::PRISME_NAME_PREFIX}DB_BUILDER_#{t_s}", @job_xml, url, user, password, track_child_job)
      $log.debug("Jenkins start build called to build a db! #{job}")
      $log.debug("DB CONFIG=#{tag_name}")
    rescue => ex
      tag_name = ex.message
      $log.error("DB CONFIG failed. #{ex}")
      $log.error(ex.backtrace.join("\n"))
      raise ex
    ensure
      save_result(tag_name, result_hash)
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