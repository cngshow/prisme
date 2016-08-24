module AdminUserEditHelper
  def role_checkbox(role)
    role = role.to_s if role.is_a? Symbol
    ret = %{
<input type="checkbox" name="cbx_#{role}" id="cbx_#{role}" value="true" class="cbx"/>
&nbsp;&nbsp;<label for="cbx_#{role}">#{role.split('_').map(&:capitalize).join(' ')}</label>
    }
    ret.html_safe
  end

  def no_match_row
    '<tr valign="top"><td colspan="3" align="center">No Users found that match the filter criteria</td></tr>'.html_safe
  end
end
