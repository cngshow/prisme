class NavigationPolicy < Struct.new(:user, :navigation)

  def registered?
    !user.nil? && (user.has_role?(Roles::ADMINISTRATOR) || user.has_role?(Roles::SUPER_USER) )
  end

  def admin?
    # promote the first user to an admin
    if (User.count == 1 && !user.nil? && !user.has_role?(Roles::SUPER_USER))
      user.add_role(Roles::SUPER_USER)
      user.save
    end

    !user.nil? && (user.has_role?(Roles::SUPER_USER))
  end
end
