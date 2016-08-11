class SsoiUser < ActiveRecord::Base
  before_save :ensure_read_only

  rolify

  def self.user_roles(ssoi_user_name)
    roles = []
    user = fetch_user(ssoi_user_name)
    if user
      roles = user.roles.to_a
    end
    roles
  end

  def self.fetch_user(ssoi_user_name)
    SsoiUser.where(ssoi_user_name: ssoi_user_name).first
  end

  ###########################################################
  # start - interface methods shared between user.rb and ssoi_user.rb
  ###########################################################
  def user_name
    ssoi_user_name
  end

  def user_row_id
    "#{id}_true"
  end
  ###########################################################
  # end - interface methods
  ###########################################################

  private
  def ensure_read_only
    self.add_role(Roles::READ_ONLY)
  end
end
