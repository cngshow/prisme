class SsoiUser < ActiveRecord::Base
  include PrismeUserConcern
  before_save :ensure_read_only
  validates_uniqueness_of :ssoi_user_name
  has_many :ssoi_user_role_assocs

  alias_method(:user_role_assocs, :ssoi_user_role_assocs)

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

  def self.user_and_roles(ssoi_user_name)
    roles = []
    user = fetch_user(ssoi_user_name)
    if user
      roles = user.roles.to_a
    end
    {user: user, roles: roles}
  end
end
