class AdminUserEditController < ApplicationController
  before_action :auth_admin

  def list
    # todo sort the listing and add filtering
    devise_users = User.all.to_a
    ssoi_users = SsoiUser.all.to_a
    @user_list = devise_users + ssoi_users
  end

  def update_user_roles
    uid, ssoi_user = parse_user_id(params[:user_id_to_edit])
    user = User.find(uid) unless ssoi_user
    user = SsoiUser.find(uid) if ssoi_user
    user.roles = []

    if ssoi_user
      user.admin_role_check = true
    end

    user.save

    # assign selected roles
    Roles::ALL_ROLES.each do |role|
      unless params["cbx_#{role.to_s}"].nil?
        user.add_role(role)
      end
    end

    flash_notify('Successfully updated the user roles!  These changes may take up to five minutes to propagate through the system.', {})
    redirect_to list_users_path
  end

  def delete_user
    ret = {remove_row: true, flash_options: {message: 'The user was deleted previously!'}, flash_settings: {type: 'success'}}
    uid, ssoi_user = parse_user_id(params[:user_row_id])
    user = User.find(uid) unless ssoi_user
    user = SsoiUser.find(uid) if ssoi_user

    # if user is not looked up then another user has deleted them already
    if (user)
      ret = {remove_row: true, flash_options: {message: "User #{user.user_name} has been successfully deleted!"}, flash_settings: {type: 'success'}}
      # do not allow user to delete the last user or themselves
      if !ssoi_user && User.count == 1
        ret = {remove_row: false, flash_options: {message: 'You cannot delete the last user!'}, flash_settings: {type: 'warning'}}
      elsif (prisme_user.id == uid.to_i) # todo test this!!!!
        # the user cannot delete themselves
        ret = {remove_row: false, flash_options: {message: 'You cannot delete yourself!'}, flash_settings: {type: 'warning'}}
      end
      # delete the user if we are removing the row
      if (ret[:remove_row])
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
