module AdminUserEditHelper
  FILTER_GROUP = 'user_admin_filters'
  QUICK_SEARCH = 'user_quick_search'
  ROLE_REVIEW = 'admin_role_review'
  REQUEST_ID = 'request_id'

  def role_checkbox(role)
    ret = %{
<input type="checkbox" name="cbx_#{role}" id="cbx_#{role}" value="true" class="cbx" onclick="modeling_role_clicked(this);"/>
&nbsp;&nbsp;<label for="cbx_#{role}">#{Roles.gui_string(role)}</label>
    }
    ret.html_safe
  end

  def isaac_uuid_checkbox(role, uuid)
    cbx_name = "cbx_#{role}|#{uuid[:uuid]}"

    ret = %{
<input title="#{uuid[:title]}" type="checkbox" name="#{cbx_name}" id="#{cbx_name}" value="true" class="cbx" #{uuid[:checked] ? 'checked' : ''} onclick="isaac_uuid_clicked(this);"/>
&nbsp;&nbsp;<label for="#{cbx_name}" title="#{uuid[:title]}">#{uuid[:display_name]}</label><br>
    }
    ret.html_safe
  end

  def isaac_undeployed_uuid_checkbox(role, uuid)
    uuid_prop_arr = UuidProp.corresponding_issac_uuids(uuid: uuid, &UuidProp::ISAAC_DB_UUID_SELECTOR)
    ret = []
    uuid_prop_arr.each_with_index do |prop, idx|
      name = "#{prop.get(key: UuidProp::Keys::NAME)} (#{uuid})" || uuid
      cbx_name = "cbx_#{role}|#{uuid}|#{idx}"
      cbx_string = %{
<input title="Undeployed UUID: #{name}" type="checkbox" name="#{cbx_name}" id="#{cbx_name}" value="true" class="cbx" checked onclick="isaac_uuid_clicked(this);"/>
&nbsp;&nbsp;<label for="#{cbx_name}" title="Undeployed/Unreachable ISAAC: #{name}" style="color: red">Undeployed/Unreachable ISAAC: #{name}</label><br>
    }
      ret << cbx_string
    end
    ret.join('<br>').html_safe
  end

  def loading_uuids_message(div_classname:)
    ret = []
    Roles::MODELING_ROLES.each do |role|
      loading_div = "<div class=\"isaac_uuid_cbxs #{div_classname}\"><i class=\"fa fa-cog fa-spin\" aria-hidden=\"true\"></i>&nbsp;Loading ISAAC UUIDs. Please Wait...</div>"
      js_output = "$('#tr_#{role} > td:nth-child(2) > ul').after('#{loading_div}')"
      ret << js_output
    end
    ret.join(";\n")
  end

  def no_match_row
    '<tr valign="top"><td colspan="4" align="center">No Users found that match the filter criteria</td></tr>'.html_safe
  end

  def last_user_activity(username:)
    last_activity_record = UserActivity.where('username = ?', username).order('last_activity_at DESC').first
    last_activity_record ? display_time(last_activity_record.last_activity_at) : 'Unknown'
  end
end
