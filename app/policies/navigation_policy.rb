class NavigationPolicy < Struct.new(:user, :navigation)

  def registered?
    !user.nil?
  end

  def admin?
    registered? && user.administrator
  end

end