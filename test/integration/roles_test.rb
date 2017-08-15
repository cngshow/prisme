$testing = true
require 'test_helper'
require './config/initializers/01_prisme_init'
require './test/integration/test_user'


java_import 'gov.vha.isaac.ochre.api.PrismeRole' do |p,c|
  'JPR'
end

java_import 'gov.vha.isaac.ochre.api.PrismeRoleType' do |p,c|
  'JPRT' #Stands for Java Prisme Role Type
end

class RolesTest < ActionDispatch::IntegrationTest
  include TestUser

  test 'all_roles_available' do
    all_java_roles = JPR.values.select do |role| role.getType != JPRT::NON_USER  end.map do |role| role.name.to_sym end.sort
    role_roles = (Roles.constants & all_java_roles).sort
    assert(role_roles.eql?(all_java_roles), "Expected all the roles defined in java to be referenced in Ruby! Java has #{all_java_roles}, ruby only has #{role_roles}.  Missing #{all_java_roles - role_roles} ")
  end

 # test "roles_in_list" do
 #   setup_test_user
 #   post user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.email
 #   get list_users_path
 #   assert_equal 200, response.status
 #   preamble = 'id="cbx_THE_ROLE"'
 #   Roles::ALL_ROLES.each do |role|
 #     looking_for = preamble.gsub('THE_ROLE',role)
 #     assert(response.body =~ /#{looking_for}/m,"I could not find #{looking_for} in the form!")
 #   end
 # end
end
