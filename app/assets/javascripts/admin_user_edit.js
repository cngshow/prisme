function modeling_role_clicked(elem) {
    if (! elem.checked) {
        //the user is unchecking the role so uncheck all related isaac uuid checkboxes
        $("[id^=cbx_reviewer\\|]").prop('checked',false);
    }
}

function isaac_uuid_clicked(elem) {
    if (elem.checked) {
        //ensure that the user has the role checked
        var role = elem.id.split('|')[0];
        $('#' + role).prop('checked', true);
    }
}
