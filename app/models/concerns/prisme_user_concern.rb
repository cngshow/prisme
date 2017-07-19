module PrismeUserConcern
  extend ActiveSupport::Concern

  SSOI_USER = :ssoi
  DEVISE_USER = :devise

  included do
    rolify
    scope :filter_admin_role_check, -> (bool) { where(admin_role_check: bool) }

    def self.filter_user_name(name)
      where("lower(#{self.to_s.eql?(SsoiUser.to_s) ? 'ssoi_user_name' : 'email'}) like ?", "%#{name.downcase}%")
    end
  end

  # instance methods here
  def user_name
    self.is_a?(SsoiUser) ? ssoi_user_name : email
  end

  def user_row_id
    "#{id}_#{self.is_a?(SsoiUser)}"
  end

  def add_uuid_to_role(role_string:, isaac_db_uuid:)
    raise "The passed in role is not a modeling role.  Valid modeling roles are #{Roles::MODELING_ROLES}" unless Roles::MODELING_ROLES.include?(role_string)
    ura = user_role_assocs.select {|ura| ura.role.name.eql?(role_string)}
    unless ura.empty?
      ura.first.add_isaac_db_uuid(isaac_db_uuid)
    end
  end

  def remove_uuid_from_role(role_string:, isaac_db_uuid:)
    raise "The passed in role is not a modeling role.  Valid modeling roles are #{Roles::MODELING_ROLES}" unless Roles::MODELING_ROLES.include?(role_string)
    ura = user_role_assocs.select {|ura| ura.role.name.eql?(role_string)}
    unless ura.empty?
      ura.first.remove_isaac_db_uuid(isaac_db_uuid)
    end
  end

  private
  def ensure_read_only
    self.add_role(Roles::READ_ONLY)
  end
end

# 10001 editor  {deployments: [serverA], terminologies: [vhat]}
# 10001 readonly  {deployments: [serverA], terminologies: [loinc, snomed, vhat]}