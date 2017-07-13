class UserRoleAssoc < ActiveRecord::Base
  self.table_name = "users_roles"
  belongs_to :user

  # belongs_to :role
  def fetch_metadata
    JSON.parse(role_metadata).to_s
  end

  def write_metadata?(**hash)
    role_metadata = hash.to_json
    puts "r is #{role_metadata}"
    update(role_metadata: role_metadata)
    #save
  end

  def write_metadata!(**hash)
    role_metadata = hash.to_json
    save!
  end

  def has_isaac_uuid(uuid)
  end
end

=begin
a = User.first.user_role_assocs.first
a.write_metadata?(foo: 'fff')
=end