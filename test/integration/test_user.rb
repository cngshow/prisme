module TestUser
  def setup_test_user
    @user = User.new
    @user.email = 'test@tester.com'
    @user.password = @user.email
    @user.add_role(Roles::SUPER_USER)
    @user.save
  end
end