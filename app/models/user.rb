class User < ActiveRecord::Base
  include PrismeUserConcern
  before_save :ensure_read_only
  has_many :user_role_assocs

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable, :validatable

  def add_uuid_to_role(role_string:, isaac_db_uuid:)
    raise "The passed in role is not a modeling role.  Valid modeling roles are #{Roles::MODELING_ROLES}" unless Roles::MODELING_ROLES.include?(role_string)

  end
end
