module SeedData
  VA_DEV = [
      {
          service: {name: 'Tomcat Application Server', description: 'Tomcat Application Server', service_type: PrismeService::TOMCAT},
          props: [
              {key: PrismeService::CARGO_REMOTE_USERNAME, value: 'devadmin'},
              {key: PrismeService::CARGO_REMOTE_PASSWORD, value: '-Uh51xyctsi5Z4YmeUKk-hYRKrT0_9ORlneeymUdipE=$$$SK-5E3LaJmdL914tkTje6Al0DzMcIss5nBhUc3RrdKRRsEmqviGRdYiBgVc4T9jp10Mj4PkXpmY1JFrrUOO1sw=='},
              {key: PrismeService::CARGO_REMOTE_URL, value: 'https://vadev.mantech.com:4848/manager'}
          ]
      },
      {
          service: {name: 'Nexus Artifactory', description: 'Nexus Artifactory', service_type: PrismeService::NEXUS},
          props: [
              {key: PrismeService::NEXUS_REPOSITORY_URL, value: 'https://vadev.mantech.com:8080/nexus/content/groups/everything/'},
              {key: PrismeService::NEXUS_PUBLICATION_URL, value: 'https://vadev.mantech.com:8080/nexus/content/repositories/termdata/'},
              {key: PrismeService::NEXUS_USER, value: 'devtest'},
              {key: PrismeService::NEXUS_PWD, value: 'Un_x4n2VBVYEoOcvxx4jphcc3w8NDfi3nrOJVXm-Cs0=$$$tuBdx5HPa_1YpjAuKsp2B0yYvqT7PFQfk6GwIC3JO9Feww5YBGPJr2STreydB9lC'}
          ]
      },
      {
          service: {name: 'GIT', description: 'GIT Version Control', service_type: PrismeService::GIT},
          props: [
              {key: PrismeService::GIT_ROOT, value: 'https://vadev.mantech.com:4848/git/'},
              {key: PrismeService::GIT_USER, value: 'devtest'},
              {key: PrismeService::GIT_PWD, value: 'Un_x4n2VBVYEoOcvxx4jphcc3w8NDfi3nrOJVXm-Cs0=$$$tuBdx5HPa_1YpjAuKsp2B0yYvqT7PFQfk6GwIC3JO9Feww5YBGPJr2STreydB9lC'}
          ]
      },
      {
          service: {name: 'Jenkins Build Server', description: 'Jenkins Build Server', service_type: PrismeService::JENKINS},
          props: [
              {key: PrismeService::JENKINS_ROOT, value: 'https://vadev.mantech.com:8081/jenkins'},
              {key: PrismeService::JENKINS_USER, value: 'devtest'},
              {key: PrismeService::JENKINS_PWD, value: 'Un_x4n2VBVYEoOcvxx4jphcc3w8NDfi3nrOJVXm-Cs0=$$$tuBdx5HPa_1YpjAuKsp2B0yYvqT7PFQfk6GwIC3JO9Feww5YBGPJr2STreydB9lC'}
          ]
      }
  ]

end

=begin
irb(main):158:0> CipherSupport.instance.encrypt(unencrypted_string: 'devtesthardtoguess')
2017-06-20 12:33:16,472 main ERROR Attempted to append to non-started appender RailsAppender
=> "-Uh51xyctsi5Z4YmeUKk-hYRKrT0_9ORlneeymUdipE=$$$SK-5E3LaJmdL914tkTje6Al0DzMcIss5nBhUc3RrdKRRsEmqviGRdYiBgVc4T9jp10Mj4PkXpmY1JFrrUOO1sw=="
irb(main):159:0> CipherSupport.instance.encrypt(unencrypted_string: 'devtest')
=> "Un_x4n2VBVYEoOcvxx4jphcc3w8NDfi3nrOJVXm-Cs0=$$$tuBdx5HPa_1YpjAuKsp2B0yYvqT7PFQfk6GwIC3JO9Feww5YBGPJr2STreydB9lC"
=end
