module AdminUserEditHelper
  FILTER_GROUP = 'user_admin_filters'
  QUICK_SEARCH = 'user_quick_search'
  ROLE_REVIEW = 'admin_role_review'

  def role_checkbox(role)
    role = role.to_s if role.is_a? Symbol
    ret = %{
<input type="checkbox" name="cbx_#{role}" id="cbx_#{role}" value="true" class="cbx"/>
&nbsp;&nbsp;<label for="cbx_#{role}">#{role.split('_').map(&:capitalize).join(' ')}</label>
    }
    ret.html_safe
  end

  def no_match_row
    '<tr valign="top"><td colspan="4" align="center">No Users found that match the filter criteria</td></tr>'.html_safe
  end

  def last_user_activity(username:)
    last_activity_record = UserActivity.where('username = ?', username).order('last_activity_at DESC').first
    last_activity_record ? display_time(last_activity_record.last_activity_at) : 'Unknown'
  end
end
