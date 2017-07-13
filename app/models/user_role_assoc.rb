class UserRoleAssoc < ActiveRecord::Base
  self.table_name = "users_roles"
  belongs_to :user

  # belongs_to :role
  def fetch_role_metadata
    JSON.parse(role_metadata)
  end

  def write_metadata(**hash)
    role_metadata = hash.to_json
    update!
  end

  def has_isaac_uuid(uuid)
  end
end
