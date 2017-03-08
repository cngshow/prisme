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

// var poll_paths = {'checksum' : gon.routes.checksum_request_poll_path, 'discovery' : gon.routes.discovery_request_poll_path};
/*

function results_table_poll(table_id) {
    var poll_table_info = table_id.split('_');// poll_paths[poll_table_info[0]]
    var poll_path = gon.routes.checksum_request_poll_path;
    var id = poll_table_info[1];
    console.log('poll table info1...' + table_id);

    $.get(poll_path, {request_id: id}, function (data) {
        console.log("returning from poll");
        var req_tbl = $('#' + table_id);
        req_tbl.find('tbody').html(data);

        console.log("-------------done? " + req_tbl.data('done'));

        //check if we continue polling
        if (! req_tbl.data('done')) {
            setTimeout(function () {
                results_table_poll(table_id);
            }, 5000);
        }
        // awaiting_poll_results = false;
    });
}
*/

function checksum_discovery_table_poll(table_id, poll_path) {
    var poll_table_info = table_id.split('_');
    var id = poll_table_info[1];
    console.log('poll table info...' + table_id);

    $.get(poll_path, {request_id: id}, function (data) {
        console.log("returning from poll");
        var req_tbl = $('#' + table_id);
        req_tbl.find('tbody').html(data);

        console.log("-------------done? " + req_tbl.data('done'));

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

//function for displaying hl7 message data with discovery
function discovery_hl7_message(tr_id) {
    $('#view_discovery_hl7_modal').modal('hide');
    var row = $('#' + tr_id);
    var hl7_message = row.data('hl7_message');
    console.log("tr_id is " + tr_id + " :: " + hl7_message + ' :: ' + hl7_message);
    var site_name = row.find('td.site_name').text();
    var subset_name = row.find('td.subset_name').text();
    $('#view_discovery_hl7_modal_title').text(site_name + ' - ' + subset_name);
    $('#textarea_discovery_hl7').val(hl7_message);
    $('#view_discovery_hl7_modal').modal('show');
}