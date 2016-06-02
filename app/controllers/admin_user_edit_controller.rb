class AdminUserEditController < ApplicationController
  before_action :auth_admin

  def list
    # todo sort the listing and add filtering
    @user_list = User.all
  end

  def update_user_roles
    user_id = params[:user_id]
    user = User.find(user_id)

    Roles::ALL_ROLES.each do |role|
      params["cbx_#{role.to_s}"].nil? ? user.remove_role(role) : user.add_role(role)
    end
    ajax_flash('Successfully updated the user roles!  These changes may take up to five minutes to propagate through the system.', {type: 'success'})
    redirect_to list_users_path
  end

  def delete_user
    ret = {remove_row: true, flash_options: {message: 'The user was deleted previously!'}, flash_settings: {type: 'success'}}
    user_id = params[:id]
    u = User.find(user_id)

    # if user is not looked up then another user has deleted them already
    if (u)
      ret = {remove_row: true, flash_options: {message: "User with email #{u.email} has been successfully deleted!"}, flash_settings: {type: 'success'}}
      # do not allow user to delete the last user or themselves
      if User.count == 1
        ret = {remove_row: false, flash_options: {message: 'You cannot delete the last user!'}, flash_settings: {type: 'warning'}}
      elsif (current_user.id == user_id.to_i)
        # the user cannot delete themselves
        ret = {remove_row: false, flash_options: {message: 'You cannot delete yourself!'}, flash_settings: {type: 'warning'}}
      end
      # delete the user if we are removing the row
      if (ret[:remove_row])
        u.destroy
      end
    end
    # return the results to the ajax call as json
    render json: ret
  end
end
