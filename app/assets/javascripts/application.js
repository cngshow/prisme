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
// select2 drop down js library
//= require select2
// require ag-grid/ag-grid
// require jquery.smartWizard/jquery.smartWizard
//= require jquery.steps-1.1.0/jquery.steps
//= require jquery-validation/jquery.validate.min
//= require moment/moment
// this is for ajax_flash notifications
//= require bootstrap-notify
//= require_tree .

function format_epoch_in_local(epoch) {
    var ret = epoch;

    if ($.isNumeric(epoch)) {
        var i = parseInt(epoch) * 1000;
        ret = new Date(i).toLocaleString();
    }
    return ret;
}

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
                case 'ph':
                    options['placeholder'] = dataset[value];
                    break;
                case 'w':
                    options['width'] = dataset[value];
                    break;
            }
        });
        $(element).select2(options);
    });
}
