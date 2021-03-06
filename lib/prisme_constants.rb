module PrismeConstants
  module JobTags
    TERMINOLOGY_CONVERTER = 'terminology_converter_tag'
    TERMINOLOGY_DB_BUILDER = 'terminology_db_builder_tag'
    APP_DEPLOYER = 'app_deployer'
  end
  module ENVIRONMENT
    DEV = :DEV
    SQA = :INTEGRATION
    INTEGRATION = SQA
    PRE_PROD = :'PRE-PROD'
    PROD = :PROD
    DEV_BOX = :DEV_BOX
  end
  module URL
    SCHEME = Rails.env.development? ?  'http' : 'https'
    CONTEXT = 'rails_prisme'
    PORT = Rails.env.development? ? 3000 : 8080
  end
end
