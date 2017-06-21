module SeedData
  AITC_DEV = [
      {
          service: {name: 'Tomcat Application Server', description: 'Tomcat Application Server', service_type: PrismeService::TOMCAT},
          props: [
              {key: PrismeService::CARGO_REMOTE_USERNAME, value: 'devtest'},
              {key: PrismeService::CARGO_REMOTE_PASSWORD, value: 'YTc-sZDZORkKjV8kjCommv4yp8fvYugnDy5xhr06XK1Ne4iYTMtPoAuhk4Qbwymwd_nktZ4e8jUjsYxoJjixiw=='},
              {key: PrismeService::CARGO_REMOTE_URL, value: 'https://vaauscttweb80.aac.va.gov:8080/manager'}
          ]
      },
      {
          service: {name: 'Nexus Artifactory', description: 'Nexus Artifactory', service_type: PrismeService::NEXUS},
          props: [
              {key: PrismeService::NEXUS_REPOSITORY_URL, value: 'https://vaauscttdbs81.aac.va.gov:8443/nexus/content/groups/public'},
              {key: PrismeService::NEXUS_PUBLICATION_URL, value: 'https://vaauscttdbs81.aac.va.gov:8443/nexus/content/repositories/termdata/'},
              {key: PrismeService::NEXUS_USER, value: 'devtest'},
              {key: PrismeService::NEXUS_PWD, value: 'YTc-sZDZORkKjV8kjCommv4yp8fvYugnDy5xhr06XK1Ne4iYTMtPoAuhk4Qbwymwd_nktZ4e8jUjsYxoJjixiw=='}
          ]
      },
      {
          service: {name: 'GIT', description: 'GIT Version Control', service_type: PrismeService::GIT},
          props: [
              {key: PrismeService::GIT_ROOT, value: 'https://vaauscttdbs80.aac.va.gov:8080/git/'},
              {key: PrismeService::GIT_USER, value: 'devtest'},
              {key: PrismeService::GIT_PWD, value: 'YTc-sZDZORkKjV8kjCommv4yp8fvYugnDy5xhr06XK1Ne4iYTMtPoAuhk4Qbwymwd_nktZ4e8jUjsYxoJjixiw=='}
          ]
      },
      {
          service: {name: 'Jenkins Build Server', description: 'Jenkins Build Server', service_type: PrismeService::JENKINS},
          props: [
              {key: PrismeService::JENKINS_ROOT, value: 'https://vaauscttdbs81.aac.va.gov:8080/jenkins'},
              {key: PrismeService::JENKINS_USER, value: 'devtest'},
              {key: PrismeService::JENKINS_PWD, value: 'YTc-sZDZORkKjV8kjCommv4yp8fvYugnDy5xhr06XK1Ne4iYTMtPoAuhk4Qbwymwd_nktZ4e8jUjsYxoJjixiw=='}
          ]
      }
  ]

end

=begin
irb(main):030:0> CipherSupport.instance.encrypt(unencrypted_string: 'devtesthardtoguess')
=> "YTc-sZDZORkKjV8kjCommv4yp8fvYugnDy5xhr06XK1Ne4iYTMtPoAuhk4Qbwymwd_nktZ4e8jUjsYxoJjixiw=="
irb(main):031:0> CipherSupport.instance.encrypt(unencrypted_string: 'devtest')
=> "xm1xTmr6CzZvzLFHL0NYdwNhl8ttuSt-leQ9GbV-ebbgbnJn_dgpSb108cuzwctr"
=end
