var $polling = {};

function register_polling(controller, interval) {
  $polling[controller] = interval;
}

function checkPolling(controller) {
  if (! $.isEmptyObject($polling)) {
    $.each($polling, function (key, interval) {
      if (controller !== key) {
        console.log('***************** stop polling for interval ' + interval.toString());
        clearInterval(interval);
        delete $polling['' + key];
      }
    });
  }
}
