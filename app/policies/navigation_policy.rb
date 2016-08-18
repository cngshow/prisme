class NavigationPolicy < Struct.new(:user, :navigation, :ssoi_headers)

  def registered?
    ! curr_user.nil?
  end

  def admin?
    cu = curr_user

    # promote the first user to an admin
    if User.count == 1 && !cu.nil? && cu.is_a?(User) && !cu.has_role?(Roles::SUPER_USER)
      user.add_role(Roles::SUPER_USER)
      user.save
    end

    !cu.nil? && (cu.has_role?(Roles::SUPER_USER) || cu.has_role?(Roles::ADMINISTRATOR))
  end

  private
  def curr_user
    ssoi_headers.nil? ? user : ssoi_headers[ApplicationController::SSOI_USER]
  end
end
