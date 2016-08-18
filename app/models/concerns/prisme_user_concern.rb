module PrismeUserConcern
  extend ActiveSupport::Concern

  included do
    rolify
    scope :filter_admin_role_check, -> (bool) { where(admin_role_check: bool) }
  end

  # instance methods here
  def user_name
    self.is_a?(SsoiUser) ? ssoi_user_name : email
  end

  def user_row_id
    "#{id}_#{self.is_a?(SsoiUser)}"
  end

  private
  def ensure_read_only
    self.add_role(Roles::READ_ONLY)
  end
end
