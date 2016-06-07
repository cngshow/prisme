class User < ActiveRecord::Base
  before_save :ensure_read_only

  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  private
  def ensure_read_only
    self.add_role(Roles::READ_ONLY)
  end
end
