# ensure a prisme super user exists if there is a corresponding yaml file in app/prismeData/prisme_super_user.yml
unless $rake
  PrismeUtilities.prisme_super_user
#ensure all site data is present in the database
  PrismeUtilities.synch_site_data
  PrismeUtilities.synch_group_data
  $terminology_parse_errors = false
  begin
    PrismeUtilities.parse_terminology_config
  rescue PrismeUtilities::TerminologyConfigParseError => ex
    #parse_terminology_config logs the errors already
    $terminology_parse_errors = true
  end
end
