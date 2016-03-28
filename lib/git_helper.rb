# java_import 'gov.va.isaac.interfaces.sync.ProfileSyncI' do |p,c|
#   'JProfileSyncI'
# end

java_import 'gov.va.isaac.AppContext' do |p,c|
  'JAppContext'
  end

java_import 'org.apache.logging.log4j.simple.SimpleLogger' do |p,c|
  'JSimpleLogger'
end

java_import 'gov.va.isaac.sync.git.SyncServiceGIT' do |p,c|
  'JSyncServiceGIT'
end

java_import 'org.apache.logging.log4j.status.StatusLogger' do |p,c|
  'JStatusLogger'
end

java_import 'org.slf4j.LoggerFactory' do |p,c|
  'JLoggerFactory'
end

java_import 'gov.va.isaac.interfaces.sync.MergeFailOption' do |p,c| 'JM' end

$e = nil
user = $PROPS['GIT.user']
password = $PROPS["GIT.password"]
repository_url = $PROPS["GIT.repository_url"]
local_folder = "./tmp/vhat-ibdf"
localFolder = java.io.File.new("./tmp/vhat-ibdf")
seperator = java.io.File.separator
$ssg = JAppContext.getService(JSyncServiceGIT)
$ssg.setRootLocation(localFolder)
begin
  puts "#{repository_url} -- #{user}"
 # $ssg.linkAndFetchFromRemote(repository_url, user, password)
 # $ssg.addUntrackedFiles
  files = Dir.glob(local_folder+"/**/*").map {|f| File.absolute_path(f).gsub('/',seperator)}.to_java java.lang.String
  $ssg.addFiles(files)
  $ssg.updateCommitAndPush("JRuby and Java are playing nice together!!!!!!!", $PROPS['GIT.user'], $PROPS["GIT.password"],JM::KEEP_LOCAL,files)
rescue => ex
  $e = ex
end


# load('./lib/git_helper.rb')