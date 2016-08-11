class User < ActiveRecord::Base
  before_save :ensure_read_only

  rolify

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # interface methods shared between user.rb and ssoi_user.rb
  def user_name
    email
  end

  def user_row_id
    "#{id}_false"
  end

  private
  def ensure_read_only
    self.add_role(Roles::READ_ONLY)
  end
end
