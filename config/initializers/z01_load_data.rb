# ensure a prisme super user exists if there is a corresponding yaml file in app/prismeData/prisme_super_user.yml
unless $rake
  PrismeUtilities.prisme_super_user
#ensure all site data is present in the database
  PrismeUtilities.synch_site_data
end
