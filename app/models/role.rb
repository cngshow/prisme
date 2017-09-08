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

  #editors must be vuid requestors.  This business role was added later so we must fix data from earlier prisme versions.
  def self.ensure_vuid_requester
    begin
      editor = Role.where(name: Roles::EDITOR).first
      return if editor.nil?
      records = UserRoleAssoc.where(role_id: editor).to_a + SsoiUserRoleAssoc.where(role_id: editor).to_a
      records.each do |r|
        unless r.user.has_role?(Roles::VUID_REQUESTOR)
          user = r.user
          user.add_role(Roles::VUID_REQUESTOR)
          $log.always("Data integrity check: adding VUID requesting role to #{user.user_name}")
        end
      end
    rescue => ex
      $log.error("Failure to ensure_vuid_requester! #{ex}")
      $log.error(ex.backtrace.join("\n"))
    end
  end

end