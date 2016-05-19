module WelcomeHelper
  def action_button_bar(deployment, service_id)
    ret = %{
      <div style="display: inline-block">
      <a class="btn btn-default" role="button" onclick="tomcat_app(SERVICE_ID, 'START_STOP_ACTION', 'DEPLOYMENT');"><i class="fa START_STOP_ICON" aria-hidden="true"></i>&nbsp;START_STOP_LABEL</i></a>
      <a class="btn btn-default" role="button" onclick="tomcat_app(SERVICE_ID, 'undeploy', 'DEPLOYMENT');"><i class="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Undeploy</i></a>
      </div>
    }

    # check the deployment state to see if it is running, etc.
    replacement_strings = %w(start fa-play-circle Start)

    if (deployment[:state].eql?('running'))
      replacement_strings = %w(stop fa-stop-circle-o Stop)
    end

    ret.gsub!('START_STOP_ACTION', replacement_strings[0]).gsub!('START_STOP_ICON', replacement_strings[1]).gsub!('START_STOP_LABEL', replacement_strings[2])
    ret.gsub!('DEPLOYMENT', deployment[:war_name])
    ret.gsub!('SERVICE_ID', service_id.to_s)
    ret.html_safe
  end
end
