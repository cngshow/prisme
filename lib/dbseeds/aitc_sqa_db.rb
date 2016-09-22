module SeedData
  AITC_SQA = [
      {
          service: {name: 'Tomcat Application Server', description: 'Tomcat Application Server', service_type: PrismeService::TOMCAT},
          props: [
              {key: PrismeService::CARGO_REMOTE_USERNAME, value: 'devtest'},
              {key: PrismeService::CARGO_REMOTE_PASSWORD, value: '["jK\x90\xA1\x1Fk\x87\xB6\xAB\xA3\xC5\xE7~\xBA\x1AK", "k]\x95\xD8w\x15\xFE\xD3\xC7\xDC\xAC\x9E\x1C\xD0bG"]'},
              {key: PrismeService::CARGO_REMOTE_URL, value: 'https://vaausdbsctt700.aac.va.gov:8080/manager'}
          ]
      },
      {
          service: {name: 'Nexus Artifactory', description: 'Nexus Artifactory', service_type: PrismeService::NEXUS},
          props: [
              {key: PrismeService::NEXUS_REPOSITORY_URL, value: 'https://vaausappctt702.aac.va.gov:8443/nexus/content/groups/everything/'},
              {key: PrismeService::NEXUS_PUBLICATION_URL, value: 'https://vaausappctt702.aac.va.gov:8443/nexus/content/repositories/termdata/'},
              {key: PrismeService::NEXUS_USER, value: 'devtest'},
              {key: PrismeService::NEXUS_PWD, value: '["jK\x90\xA1\x1Fk\x87\xB6\xAB\xA3\xC5\xE7~\xBA\x1AK", "k]\x95\xD8w\x15\xFE\xD3\xC7\xDC\xAC\x9E\x1C\xD0bG"]'}
          ]
      },
      {
          service: {name: 'GIT', description: 'GIT Version Control', service_type: PrismeService::GIT},
          props: [
              {key: PrismeService::GIT_REPOSITORY_URL, value: 'https://vaausdbsctt700.aac.va.gov:8080/git/r/repo_name.git'},
              {key: PrismeService::GIT_USER, value: 'devtest'},
              {key: PrismeService::GIT_PWD, value: '["jK\x90\xA1\x1Fk\x87\xB6\xAB\xA3\xC5\xE7~\xBA\x1AK", "k]\x95\xD8w\x15\xFE\xD3\xC7\xDC\xAC\x9E\x1C\xD0bG"]'}
          ]
      },
      {
          service: {name: 'Jenkins Build Server', description: 'Jenkins Build Server', service_type: PrismeService::JENKINS},
          props: [
              {key: PrismeService::JENKINS_ROOT, value: 'https://vaausappctt702.aac.va.gov:8080'},
              {key: PrismeService::JENKINS_USER, value: 'devtest'},
              {key: PrismeService::JENKINS_PWD, value: '["jK\x90\xA1\x1Fk\x87\xB6\xAB\xA3\xC5\xE7~\xBA\x1AK", "k]\x95\xD8w\x15\xFE\xD3\xC7\xDC\xAC\x9E\x1C\xD0bG"]'}
          ]
      }
  ]

end
