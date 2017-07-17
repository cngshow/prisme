$testing = true
require 'test_helper'
require './config/initializers/01_prisme_init'

java_import 'gov.vha.isaac.ochre.api.PrismeRole' do |p,c|
  'JPR'
end

class RolesTest < ActionDispatch::IntegrationTest

  test 'all_roles_available' do
    all_java_roles = JPR.values.map do |role| role.name.to_sym end.sort
    role_roles = (Roles.constants & all_java_roles).sort
    assert(role_roles.eql?(all_java_roles), "Expected all the roles defined in java to be referenced in Ruby! Java has #{all_java_roles}, ruby only has #{role_roles}.  Missing #{all_java_roles - role_roles} ")
  end
end