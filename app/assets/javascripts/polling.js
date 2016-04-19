var polling = (function () {
    // privates
    var registrations = {};

    function isPolling(controller) {
        return registrations[controller];
    }

    function register(controller, callback, interval_seconds) {
        if (registrations[controller]) {
            return false;
        }
        registrations[controller] = setInterval(callback, interval_seconds);
    }

    function checkPolling(controller) {
        if (!$.isEmptyObject(registrations)) {
            $.each(registrations, function (key, interval) {
                if (controller !== key) {
                    console.log('***************** stop polling for interval ' + interval.toString());
                    clearInterval(interval);
                    delete registrations['' + key];
                }
            });
        }
    }

    // Return an object exposed to the public
    return {
        // public methods
        // register a controller and its
        registerController: register,

        // call checkPolling to turn off any polling not associated with the controller key passed
        checkPolling: checkPolling,

        // Public alias to a private function
        isPolling: isPolling
    };
})();
