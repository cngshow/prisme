module WelcomeHelper
  def action_button_bar(deployment, service_id, war_uuid)
    ret = %{
<div style="display: inline-block" id="SERVICE_ID-DEPLOYMENT_ID">
<button id="SERVICE_ID-START_STOP_ACTION-DEPLOYMENT_ID" class="btn btn-default" DATA_WAR_UUID onclick="tomcat_app(this, SERVICE_ID, 'START_STOP_ACTION', 'DEPLOYMENT');" tabindex="0"><i class="fa START_STOP_ICON fa-fw" aria-hidden="true"></i>&nbsp;START_STOP_LABEL</button>
<button id="SERVICE_ID-undeploy-DEPLOYMENT_ID" class="btn btn-default" DATA_WAR_UUID onclick="tomcat_app(this, SERVICE_ID, 'undeploy', 'DEPLOYMENT');" tabindex="0"><i class="fa fa-trash-o fa-fw" aria-hidden="true"></i>&nbsp;Undeploy</button>
</div>
}
    # check the deployment state to see if it is running, etc.
    replacement_strings = %w(start fa-play-circle Start)

    if deployment[:state].eql?('running')
      replacement_strings = %w(stop fa-stop-circle-o Stop)
    end

    ret.gsub!('START_STOP_ACTION', replacement_strings[0]).gsub!('START_STOP_ICON', replacement_strings[1]).gsub!('START_STOP_LABEL', replacement_strings[2])
    ret.gsub!('DEPLOYMENT_ID', deployment[:war_name].gsub('.','_'))
    ret.gsub!('DEPLOYMENT', deployment[:war_name])
    ret.gsub!('SERVICE_ID', service_id.to_s)
    ret.gsub!('DATA_WAR_UUID', war_uuid ? "data-war_uuid='#{war_uuid}'" : '')
    ret.html_safe
  end

  def fetch_komets_isaac(row:)
    r_val = ''
    if row.has_key? :komets_isaac_version
      r_val = " -- #{row.fetch(:komets_isaac_version)}"
    end
    r_val
  end
end
