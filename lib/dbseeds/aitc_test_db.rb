module SeedData
  AITC_TEST = [
      {
          service: {name: 'Tomcat Application Server', description: 'Tomcat Application Server', service_type: PrismeService::TOMCAT},
          props: [
              {key: 'cargo.remote.username', value: 'devtest'},
              {key: 'cargo.remote.password', value: '["jK\x90\xA1\x1Fk\x87\xB6\xAB\xA3\xC5\xE7~\xBA\x1AK", "k]\x95\xD8w\x15\xFE\xD3\xC7\xDC\xAC\x9E\x1C\xD0bG"]'},
              {key: 'cargo.remote.manager.url', value: 'https://put-in-path-here/manager'}
          ]
      },
      {
          service: {name: 'Nexus Artifactory', description: 'Nexus Artifactory', service_type: PrismeService::NEXUS},
          props: [
              {key: 'nexus_repository_url', value: 'https://put-in-path-here:port/nexus/content/groups/everything/'},
              {key: 'nexus_publication_url', value: 'https://put-in-path-here:port/nexus/content/repositories/termdata/'},
              {key: 'nexus_user', value: 'devtest'},
              {key: 'nexus_pwd', value: '["jK\x90\xA1\x1Fk\x87\xD7\xC3\xD8\xA8\x9A\x18\xD4fC"]'}
          ]
      },
      {
          service: {name: 'GIT', description: 'GIT Version Control', service_type: PrismeService::GIT},
          props: [
              {key: 'git_repository_url', value: 'https://put-in-path-here:port/git/r/db_test.git'},
              {key: 'git_user', value: 'devtest'},
              {key: 'git_pwd', value: '["jK\x90\xA1\x1Fk\x87\xD7\xC3\xD8\xA8\x9A\x18\xD4fC"]'}
          ]
      },
      {
          service: {name: 'Jenkins Build Server', description: 'Jenkins Build Server', service_type: PrismeService::JENKINS},
          props: [
              {key: 'jenkins_root', value: 'https://put-in-path-here:port'},
              {key: 'jenkins_user', value: 'devtest'},
              {key: 'jenkins_pwd', value: '["jK\x90\xA1\x1Fk\x87\xB6\xAB\xA3\xC5\xE7~\xBA\x1AK", "k]\x95\xD8w\x15\xFE\xD3\xC7\xDC\xAC\x9E\x1C\xD0bG"]'}
          ]
      }
  ]

end