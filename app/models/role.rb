class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, :join_table => :users_roles
  has_and_belongs_to_many :ssoi_users, :join_table => :ssoi_users_roles

  belongs_to :resource,
             :polymorphic => true
  # :optional => true

  validates :resource_type,
            :inclusion => {:in => Rolify.resource_types},
            :allow_nil => true

  scopify

  BAD_ROLE_SQL = %Q{select a.id from roles a where not exists (select * from roles b where a.id = b.id and b.name in (#{Roles::ALL_ROLES.map do |e|
    '\''<< e << '\''
  end.join(',')}))}


  def self.cleanup_removed_roles
    begin
      Role.find_by_sql(Role::BAD_ROLE_SQL).each do |bad_role|
        $log.info("The following role is now defunct - #{Role.find(bad_role.id).name}, cleaning up...")
        UserRoleAssoc.destroy_all(role_id: bad_role.id)
        SsoiUserRoleAssoc.destroy_all(role_id: bad_role.id)
        Role.destroy(bad_role.id)
    end
    rescue => ex
      $log.error("Failure to cleanup defunct roles! #{ex}")
      $log.error(ex.backtrace.join("\n"))
    end
  end

end