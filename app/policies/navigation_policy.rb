class NavigationPolicy < Struct.new(:user, :navigation)

  def registered?
    !user.nil?
  end

  def admin?
    # promote the first user to an admin
    if (User.count == 1 && !user.nil? && !user.administrator)
      user.administrator = true
      user.save
    end

    registered? && user.administrator
  end
end
