class NavigationPolicy < Struct.new(:user, :navigation)

  def registered?
    $log.debug("Registered?  The user is " + user.to_s)
    !user.nil?
  end

  def admin?
    registered? && user.administrator
  end

end