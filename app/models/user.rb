class User < ActiveRecord::Base
  include PrismeUserConcern
  before_save :ensure_read_only
  has_many :user_role_assocs

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable, :validatable
end
