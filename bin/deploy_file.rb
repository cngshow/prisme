url = "http://vadev.mantech.com:8081/nexus/content/repositories/ets_tooling2/"
repository_id = "ets_tooling2"
group_id = "gov.vha.ets_tooling"
artifact_id = "ets_tooling_main"
version = "1.0." + `git describe --always --tags`
packaging="war"
file='C:\work\ETS\ets_prisme\empty.war'
user="devtest"
password="devtest"
I am here
command = "mvn deploy:deploy-file -Durl=#{url} -DrepositoryId=#{repository_id} -DgroupId=#{group_id} "
command << "-DartifactId=#{artifact_id} -Dversion=#{version} -Dpackaging=#{packaging} -Dfile=#{file} "
#system 'pwd'
#system(command)
command = %Q(curl -v -F r=#{repository_id} -F g=#{group_id}  -F a=#{artifact_id} -F v=#{version} )
command << %Q(-F p=#{packaging}  -F file=#{file} -u #{user}:#{password} )
command << %Q(#{url} )
system command

# curl -v \
#     -F "r=releases" \
#     -F "g=com.acme.widgets" \
#     -F "a=widget" \
#     -F "v=0.1-1" \
#     -F "p=tar.gz" \
#     -F "file=@./widget-0.1-1.tar.gz" \
#     -u myuser:mypassword \
#     http://localhost:8081/nexus/service/local/artifact/maven/content
# mvn deploy:deploy-file \
#     -Durl=$REPO_URL \
#     -DrepositoryId=$REPO_ID \
#     -DgroupId=org.myorg \
#     -DartifactId=myproj \
#     -Dversion=1.2.3  \
#     -Dpackaging=zip \
#     -Dfile=myproj.zip