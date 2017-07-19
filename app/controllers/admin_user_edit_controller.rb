class AdminUserEditController < ApplicationController
  before_action :any_administrator

  def list
    unless session.has_key?(AdminUserEditHelper::FILTER_GROUP)
      session[AdminUserEditHelper::FILTER_GROUP] = {}
      session[AdminUserEditHelper::FILTER_GROUP][AdminUserEditHelper::QUICK_SEARCH] = ''
      session[AdminUserEditHelper::FILTER_GROUP][AdminUserEditHelper::ROLE_REVIEW] = 'all'
    end
  end

  def ajax_load_user_list
    user_quick_search = session[AdminUserEditHelper::FILTER_GROUP][AdminUserEditHelper::QUICK_SEARCH]
    user_quick_search = params[AdminUserEditHelper::QUICK_SEARCH] if params[AdminUserEditHelper::QUICK_SEARCH]
    admin_role_review = session[AdminUserEditHelper::FILTER_GROUP][AdminUserEditHelper::ROLE_REVIEW]
    admin_role_review = params[AdminUserEditHelper::ROLE_REVIEW] if params[AdminUserEditHelper::ROLE_REVIEW]

    # default query - all users
    devise_users = User.all
    ssoi_users = SsoiUser.all

    if user_quick_search && user_quick_search.length > 0
      devise_users = User.filter_user_name(user_quick_search)
      ssoi_users = SsoiUser.filter_user_name(user_quick_search)

      unless admin_role_review.eql?('all')
        devise_users = devise_users.filter_admin_role_check(boolean(admin_role_review))
        ssoi_users = ssoi_users.filter_admin_role_check(boolean(admin_role_review))
      end
    else
      unless admin_role_review.eql?('all')
        devise_users = User.filter_admin_role_check(boolean(admin_role_review))
        ssoi_users = SsoiUser.filter_admin_role_check(boolean(admin_role_review))
      end
    end
    @user_list = devise_users.to_a + ssoi_users.to_a
    @user_list.sort_by! {|user| user.user_name}

    session[AdminUserEditHelper::FILTER_GROUP][AdminUserEditHelper::QUICK_SEARCH] = user_quick_search
    session[AdminUserEditHelper::FILTER_GROUP][AdminUserEditHelper::ROLE_REVIEW] = admin_role_review
    render :partial => 'users', :format => :html
  end

  def update_user_roles
    user = load_user_from_params(param_key: :user_id_to_edit)
    user.admin_role_check = true
    user.roles = []

    # assign selected roles
    Roles::ALL_ROLES.each do |role|
      unless params["cbx_#{role.to_s}"].nil?
        user.add_role(role)
      # else
      #   user.remove_role(role)
      end
    end

    # if the user has the editor role then they must also have the VUID requestor role as well
    if user.has_role?(Roles::EDITOR)
      user.add_role(Roles::VUID_REQUESTOR)
    end

    # save the user, flash and redirect
    user.save

    # check modeling roles for metadata uuids
    isaac_db_uuids = params.keys.select {|p| p =~ /cbx\_.*\|.*/}
    isaac_db_uuids.each do |rolePipeUuid|
      role, uuid = rolePipeUuid.split('|')
      user.add_uuid_to_role(role_string: role.gsub('cbx_',''), isaac_db_uuid: uuid)
    end

    # flash and redirect
    flash_info(message: 'Successfully updated the user roles!  These changes may take up to five minutes to propagate through the system.')
    redirect_to list_users_path
  end

  def delete_user
    ret = {remove_row: true}
    user = load_user_from_params(param_key: :user_row_id)

    # if user is not looked up then another user has deleted them already
    if user
      # do not allow user to delete the last user, themselves, or the last super user
      if !ssoi_user && User.count == 1
        ret = {remove_row: false}
        flash_alert(message: 'You cannot delete the last user!')
      elsif prisme_user == user
        # the user cannot delete themselves
        ret = {remove_row: false}
        flash_alert(message: 'You cannot delete yourself!')
      else
        super_users = User.with_any_role(:super_user)
        super_users << SsoiUser.with_any_role(:super_user)
        super_users.flatten!

        if super_users.count == 1 && super_users.first == user
          # the user cannot delete the last super user
          ret = {remove_row: false}
          flash_alert(message: 'You cannot delete the last super user!')
        end
      end
      # delete the user if we are removing the row
      if ret[:remove_row]
        user.destroy
        flash_notify(message: "User #{user.user_name} has been successfully deleted!")
      end
    else
      ret = {remove_row: true}
      flash_notify(message: 'The user was deleted previously!')
    end
    # return the results to the ajax call as json
    render json: ret
  end

  def ajax_check_modeling_roles
    user_to_edit = load_user_from_params(param_key: :user_id_to_edit)
    isaacs = TomcatUtility::TomcatDeploymentsCache.instance.get_isaac_deployments

    isaac_uuids = []
    isaacs.each do |isaac|
      tomcat = isaac.tomcat.name
      db_uuid = isaac.get_db_uuid
      isaac_name = isaac.get_name
      title = "Komets:\n#{isaac.komets.map {|k| "&#8226;"<<(k.get_name || "Not Named:  #{k.war_uuid}")}.join("\n")}"
      isaac_uuids << {uuid: db_uuid, server: tomcat, display_name: (isaac_name || "Not Named:  #{db_uuid}") << " on #{tomcat}", title: title, checked: false}
    end

    ret = []
    Roles::MODELING_ROLES.each do |role|
      isaac_uuids.each do |uuid|
        checked = false
        if user_to_edit.has_role? role
          user_role = user_to_edit.user_role_assocs.select {|ura| ura.role.name.eql?(role)}

          unless user_role.empty?
            role_metadata = user_role.first.role_metadata

            if role_metadata
              role_metadata = JSON.parse(role_metadata)

              if role_metadata.has_key?(RoleMetadataConcern::ISAAC_DB_UUIDS)
                checked = role_metadata[RoleMetadataConcern::ISAAC_DB_UUIDS].include? uuid[:uuid]
              end
            end
          end
        end

        uuid[:checked] = checked
      end

      uuid_selections = render_to_string(:partial => 'admin_user_edit/modeling_edit', :locals => {:user => user_to_edit, :modeling_role => role, :uuids => isaac_uuids})
      ret << [role, uuid_selections]
    end

    render json: ret.to_json
  end

  private
# the user id is submitted as a string in the format id|boolean where the boolean is true for ssoi and false for devise users
  def parse_user_id(user_row_id)
    uid = user_row_id.split('_').first
    ssoi_user = user_row_id.split('_').last.eql?('true')
    [uid, ssoi_user]
  end

  def load_user_from_params(param_key:)
    uid, ssoi_user = parse_user_id(params[param_key])
    ssoi_user ? SsoiUser.find(uid) : User.find(uid)
  end
end
