class AdminUserEditController < ApplicationController
  before_action :auth_admin

  def list
    unless session.has_key?(:user_admin_filters)
      session['user_admin_filters'] = {}
      session['user_admin_filters']['user_quick_search'] = ''
      session['user_admin_filters']['admin_role_review'] = 'all'
    end
  end

  def ajax_load_user_list
    a = session.inspect
    user_quick_search = session['user_admin_filters']['user_quick_search']
    user_quick_search = params['user_quick_search'] if params['user_quick_search']
    admin_role_review = session['user_admin_filters']['admin_role_review']
    admin_role_review = params['admin_role_review'] if params['admin_role_review']

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
    @user_list.sort_by! { |user| user.user_name }

    session['user_admin_filters']['user_quick_search'] = user_quick_search
    session['user_admin_filters']['admin_role_review'] = admin_role_review
    render :partial => 'users', :format => :html
  end

  def update_user_roles
    uid, ssoi_user = parse_user_id(params[:user_id_to_edit])
    user = User.find(uid) unless ssoi_user
    user = SsoiUser.find(uid) if ssoi_user
    user.admin_role_check = true
    user.roles = []

    # assign selected roles
    Roles::ALL_ROLES.each do |role|
      unless params["cbx_#{role.to_s}"].nil?
        user.add_role(role)
      end
    end

    user.save
    flash_notify('Successfully updated the user roles!  These changes may take up to five minutes to propagate through the system.', {})
    redirect_to list_users_path
  end

  def delete_user
    ret = {remove_row: true, flash_options: {message: 'The user was deleted previously!'}, flash_settings: {type: 'success'}}
    uid, ssoi_user = parse_user_id(params[:user_row_id])
    user = ssoi_user ? SsoiUser.find(uid) : User.find(uid)

    # if user is not looked up then another user has deleted them already
    if user
      ret = {remove_row: true, flash_options: {message: "User #{user.user_name} has been successfully deleted!"}, flash_settings: {type: 'success'}}
      # do not allow user to delete the last user, themselves, or the last super user
      if !ssoi_user && User.count == 1
        ret = {remove_row: false, flash_options: {message: 'You cannot delete the last user!'}, flash_settings: {type: 'warning'}}
      elsif prisme_user == user
        # the user cannot delete themselves
        ret = {remove_row: false, flash_options: {message: 'You cannot delete yourself!'}, flash_settings: {type: 'warning'}}
      else
        super_users = User.with_any_role(:super_user)
        super_users << SsoiUser.with_any_role(:super_user)
        super_users.flatten!

        if super_users.count == 1 && super_users.first == user
          # the user cannot delete the last super user
          ret = {remove_row: false, flash_options: {message: 'You cannot the last super user!'}, flash_settings: {type: 'warning'}}
        end
      end
      # delete the user if we are removing the row
      if ret[:remove_row]
        user.destroy
      end
    end
    # return the results to the ajax call as json
    render json: ret
  end

  private
  # the user id is submitted as a string in the format id|boolean where the boolean is true for ssoi and false for devise users
  def parse_user_id(user_row_id)
    uid = user_row_id.split('_').first
    ssoi_user = user_row_id.split('_').last.eql?('true')
    [uid, ssoi_user]
  end
end
