function toggleResultTable(elem) {
    var tbl = $(elem).closest('.result_hdr').find('.result_table');
    tbl.toggle( "slow", function() {
        var clazz = tbl.is(":visible") ? 'fa fa-minus-square' : 'fa fa-plus-square';
        $(elem).find('.fa').removeClass().addClass(clazz);
    });
}

function init_checksum_table_polling() {
    $('.checksum_table').each(function (index, value) {
        var table_id = $(this).attr('id');
        setTimeout(function () {
            checksum_poll(table_id);
        }, 5000);
    });
}

function checksum_poll(table_id) {
    var id = table_id.split('_')[1];
    console.log('checksum_poll...' + table_id);

    $.get(gon.routes.checksum_request_poll_path, {checksum_req_id: id}, function (data) {
        console.log("returning from poll");
        var req_tbl = $('#'+table_id);
        req_tbl.find('tbody').html(data);

        //set the status in the header
        $('#status_' + id).text('Status: ' + req_tbl.data('status'));

        console.log("-------------done? " + req_tbl.data('done'));

        //check if we continue polling
        if (! req_tbl.data('done')) {
            setTimeout(function () {
                checksum_poll(table_id);
            }, 5000);
        }
        // awaiting_poll_results = false;
    });
}