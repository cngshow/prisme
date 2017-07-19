function modeling_role_clicked(elem) {
    if (! elem.checked) {
        var selector = "[id^=" + elem.id + "\\|]";
        //the user is unchecking the role so uncheck all related isaac uuid checkboxes
        $(selector).prop('checked',false);
    }
}

function isaac_uuid_clicked(elem) {
    if (elem.checked) {
        //ensure that the user has the role checked
        var role = elem.id.split('|')[0];
        $('#' + role).prop('checked', true);
    }
}
