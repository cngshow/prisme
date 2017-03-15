// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery2
//= require jquery_ujs
//= require jquery-ui
//= require bootstrap
//= require turbolinks
//= require jsTree/jstree
//= require file_saver/FileSaver
// select2 drop down js library
//= require select2
//= require jquery.steps-1.1.0/jquery.steps
//= require jquery-validation/jquery.validate.min
//= require moment/moment
// this is for ajax_flash notifications
//= require bootstrap-notify
// = require_tree .

// JS method for bootstrap nootification flashes
function flash_notify(options, settings) {
    $.notify(options, settings);
}

function wait_cursor(on) {
    if (on) {
        $('body').addClass('wait');
    } else {
        $('body').removeClass('wait');
    }
}

function format_epoch_in_local(epoch) {
    var ret = '';

    if (epoch !== undefined && epoch !== null) {
        epoch = epoch.toString();

        if (epoch.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/)) {
            ret = new Date(epoch).toLocaleString();
        }
        else if ($.isNumeric(epoch) && epoch > 0) {
            //hack - epoch in seconds needs to be in millis for JS call below.
            //this will accept either a 13 digit number representing the current time in millis
            //or will be an epoch number in seconds. So if the length is <13 then add 3 zeros.
            // This will be a bug starting on 09/26/33658 at 21:46:40 EST.
            if (epoch.length < 13) {
                epoch += '000'
            }
            ret = new Date(parseInt(epoch)).toLocaleString();
        } else {
            ret = epoch;
        }
    }
    return ret;
}
/*

$(document).ajaxComplete(function (event, jqXHR, ajaxOptions) {
    // var h = jqXHR.getAllResponseHeaders();
    // var res = h.match(/X-Greg/gi);
    // console.log(h);
    // var h2 = JSON.parse('{' + h + '}');

    if (jqXHR.getResponseHeader('X-Greg') !== null) {
        var flashes = JSON.parse(decodeURIComponent(jqXHR.getResponseHeader('X-Greg')));
        // flash_notify(flashes.options, flashes.settings);
        for (i = 0; i < flashes.length; i++) {
            flash_notify(flashes[i].options, flashes[i].settings);
        }
        console.log('--- ' + JSON.stringify(flashes));
    }
});
*/

function init_select2() {
    $('.select2-prisme').each(function (index, element) {
        var options = {
            theme: "bootstrap",
            allowClear: true
        };
        var dataset = element.dataset;
        $.each(Object.keys(dataset), function (index, value) {
            switch (value) {
                case 'single_select':
                case 'singleSelect':
                    options['minimumResultsForSearch'] = Infinity;
                    break;
                case 'multi':
                    options['multiple'] = true;
                    if ($(element).attr('required') !== undefined) {
                        options['minimumResultsForSearch'] = 1;
                    }
                    break;
                case 'ph':
                    options['placeholder'] = dataset[value];
                    break;
                case 'w':
                    options['width'] = dataset[value];
                    break;
            }
        });
        $(element).select2(options);
        $(element).on('select2:opening', function (evt) {
            var target_name = evt.target.name + '-error';
            $('#' + target_name).remove();
        });
    });
}