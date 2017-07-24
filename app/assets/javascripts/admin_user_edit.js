function modeling_role_clicked(elem) {
    var selector = "[id^=" + elem.id + "\\|]";
    //the user is unchecking the role so uncheck all related isaac uuid checkboxes
    $(selector).prop('checked', elem.checked);
}

function isaac_uuid_clicked(elem) {
    var role = elem.id.split('|')[0];
    if (elem.checked) {
        //ensure that the user has the role checked
        $('#' + role).prop('checked', true);
    } else {
        //if all uuid checkboxes are unchecked for this role then uncheck the role itself
        var selector = "[id^=" + role + "\\|]";
        var checked = false;
        $.each($(selector), function(key, cbx_uuid){
            if ($(cbx_uuid).prop('checked')) {
                checked = true;
            }
        });

        $('#' + role).prop('checked', checked);
    }
}
