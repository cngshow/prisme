class NavigationPolicy

  attr_accessor :user, :navigation

  def initialize(user, navigation)
    @user = user
    @navigation = navigation
    add_dynamic_methods
    ensure_admin
  end

  def registered?
    ! user.nil?
  end

  def allow_local_login?
    NavigationPolicy.configured_for_local_login?
  end

  def self.allow_local_login(controller)
    controller.authorize(:navigation, :allow_local_login?)
  end

  def add_dynamic_methods
    Roles::ALL_ROLES.each do |role|
      self.define_singleton_method("#{role}?".to_sym) do
        user.has_role?(role)
      end
    end

    Roles::COMPOSITE_ROLES.each_pair do |method_name, role_array|
      self.define_singleton_method("#{method_name}?".to_sym) do
        return false unless registered?
        (@user.roles.map(&:name) & role_array).length != 0
      end
    end
  end

  def ensure_admin
    return false unless registered?
    # promote the first user to an admin
    if User.count == 1  && user.is_a?(User) && !user.has_role?(Roles::SUPER_USER)
      user.add_role(Roles::SUPER_USER)
      user.save
    end
  end

  def self.add_action_methods(on)
    #on is a controller
    #dynamically add authorization methods
    (Roles::ALL_ROLES + Roles::COMPOSITE_ROLES.keys).each do |role|
      method = "#{role}".to_sym
      method_q = "#{role}?".to_sym
      on.define_singleton_method(method) do
        authorize(:navigation, method_q)
      end
      on.define_singleton_method(method_q) do
        authorize(:navigation, method_q) rescue false
      end
    end
  end

  def self.configured_for_local_login?
    exclude_envs = ($PROPS['PRISME.disallow_local_logins_on']).split(',').map(&:strip) rescue []
    !exclude_envs.include?(PRISME_ENVIRONMENT)
  end

end

=begin
load('./app/policies/navigation_policy.rb')
=end