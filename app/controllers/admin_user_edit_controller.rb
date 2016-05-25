class AdminUserEditController < ApplicationController
  before_action :auth_admin

  def update
    begin
      users = User.all
      failed_deletes = []
      failed_updates = []
      users.each do |user|
        id = user.id
        delete_cbx = !params["delete_check_box-#{id}"].nil?
        admin_cbx = user.eql?(current_user) || !params["admin_check_box-#{id}"].nil?

        if (delete_cbx)
          user.destroy
          failed_deletes << user.email unless user.destroyed?
        else
          user.administrator = admin_cbx
          updated = user.save

          # iterate all of the roles and check the params
          Role::KOMET_ROLES.each do |role|
            params["cbx_role-#{id}-#{role.to_s}"].nil? ? user.remove_role(role) : user.add_role(role)
          end
          failed_updates << user.email unless updated
        end
      end

      if (failed_deletes.empty? and failed_updates.empty?)
        # call TomcatConcern to perform the specified action
        msg = 'Successfully updated the user listing!'
        ajax_flash(msg, {type: 'success'})
      else
        messages = {}
        messages['Deletes failed!'] = failed_deletes unless failed_deletes.empty?
        messages['Update failed!'] = failed_updates unless failed_updates.empty?
        flash[:error] = render_to_string(:partial => 'bulleted_flash', :locals => {:messages => messages})
      end
    rescue Exception => e
      messages = {}
      messages['Update failed!'] = e.to_s #or optionally [e.to_s]
      flash[:error] = render_to_string(:partial => 'bulleted_flash', :locals => {:messages => messages})
    end
    redirect_to admin_user_edit_list_path
  end

  def list
    @user_list = User.all
  end
end
