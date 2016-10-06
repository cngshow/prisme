class NavigationPolicy < Struct.new(:user, :navigation)
  def registered?
    ! user.nil?
  end

  def admin?
    # promote the first user to an admin
    if User.count == 1 && registered? && user.is_a?(User) && !user.has_role?(Roles::SUPER_USER)
      user.add_role(Roles::SUPER_USER)
      user.save
    end

    registered? && (user.has_role?(Roles::SUPER_USER) || user.has_role?(Roles::ADMINISTRATOR))
  end
end
