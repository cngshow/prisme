function toggleResultTable(elem) {
    var tbl = $(elem).closest('.result_hdr').find('.result_table');
    tbl.toggle("slow", function () {
        var clazz = tbl.is(":visible") ? 'fa fa-minus-square' : 'fa fa-plus-square';
        $(elem).find('.fa').removeClass().addClass(clazz);
    });
}

function init_checksum_table_polling() { // todo rename this - refactor this to use checksum_discovery_table_poll function
    $('.checksum_table').each(function (index, value) {
        var table_id = $(this).attr('id');
        setTimeout(function () {
            checksum_discovery_table_poll(table_id, gon.routes.checksum_request_poll_path);
        }, 5000);
    });
}

function checksum_discovery_table_poll(table_id, poll_path) {
    var poll_table_info = table_id.split('_');
    var id = poll_table_info[1];

    if ($('#'+table_id).attr('id') == undefined) {
        console.log("table "+ + table_id + " is no longer available so bailing out...");
        return false;
    }

    $.get(poll_path, {request_id: id}, function (data) {
        var req_tbl = $('#' + table_id);
        req_tbl.find('tbody').html(data);

        console.log("polling " + table_id + "------------done? " + req_tbl.data('done'));

        //check if we continue polling
        if (!req_tbl.data('done')) {
            setTimeout(function () {
                checksum_discovery_table_poll(table_id, poll_path);
            }, 5000);
        }
        // awaiting_poll_results = false;
    });
}

//function for displaying hl7 data
/*
function greg(tr_id) {
    var row = $('#' + tr_id);
    var vista = row.data('hl7_message');
    var site_name = row.find('td.site_name').text();
    var subset_name = row.find('td.subset_name').text();
    console.log("tr_id is " + tr_id + " :: " + vista + ' :: ' + site_name);

    // make ajax call to get isaac hl7 hash
    $.get(gon.routes.isaac_hl7_path, {id: tr_id}, function (data) {
        $('#view_hashes_modal_title').text(site_name + ' - ' + subset_name);
        $('#textarea_vista_hl7').val(vista);
        $('#textarea_isaac_hl7').val(data['isaac_hl7']);
        $('#view_hashes_modal').modal('show');
    });

}
*/

//function for displaying hl7 message data with discovery
function discovery_hl7_message(link, obj) {
    var $viewDiscoveryHl7Modal = $('#view_discovery_hl7_modal');
    $viewDiscoveryHl7Modal.modal('hide');

    var hl7_message = $(link).data('hl7_message');
    var tr_id = obj.tr_id;
    var current = obj.current;
    var row = $('#' + tr_id);
    var site_name = row.find('td.site_name').text();
    var subset_name = row.find('td.subset_name').text();

    $('#discovery_label').text(current ? 'CURRENT' : 'PREVIOUS');
    $('#view_discovery_hl7_modal_title').text(site_name + ' - ' + subset_name);
    $('#textarea_discovery_hl7').val(hl7_message);
    $viewDiscoveryHl7Modal.modal('show');
}
