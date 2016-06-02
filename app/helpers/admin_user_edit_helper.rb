module AdminUserEditHelper
  def role_checkbox(role)
    role = role.to_s if role.is_a? Symbol
    ret = %{
<input type="checkbox" name="cbx_#{role}" id="cbx_#{role}" value="true" class="cbx"/>
&nbsp;&nbsp;<label for="cbx_#{role}">#{role.split('_').map(&:capitalize).join(' ')}</label>
    }
    ret.html_safe
  end
end
