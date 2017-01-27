var polling = (function () {
    var registrations = {};
    var PollEnum = {
        WELCOME_CONTROLLER: 'welcome_controller',//used in navigation
        WELCOME_QUEUE: 'welcome_queue',//used for queue tabpage poll
        WELCOME_LOG_EVENTS: 'welcome_log_events',//used for log_events tabpage poll
        WELCOME_DEPLOYMENTS: 'welcome_deployments',//used for deployments tabpage poll
        TERM_SOURCE: 'terminology_source_packages',
        CONVERTER: 'converter',
        DB_BUILDER: 'db_builder',
        DEPLOYER: 'deployer',
        CHECKSUM: 'checksum',
        DISCOVERY: 'discovery',
        ADMIN_USER_EDIT: 'admin_user_edit',
        SERVICES: 'services',
        LOGIN: 'log_in',
        LOGOUT: 'log_out'
    };

    function isPolling(controller) {
        return registrations[controller];
    }

    function register(controller, callback, interval_seconds) {
        if (registrations[controller]) {
            return false;
        }
        
        // immediately call the function and then set the polling interval
        if (typeof callback === "function") {
            callback.apply(null, {});
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

    function unregister(controller) {
        if (!$.isEmptyObject(registrations)) {
            $.each(registrations, function (key, interval) {
                if (controller === key) {
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
        registerPolling: register,

        // unregister a controller explicitly
        unregisterPolling: unregister,

        // call checkPolling to turn off any polling not associated with the controller key passed
        checkPolling: checkPolling,

        // Public alias to a private function
        isPolling: isPolling,
        
        pollEnum: PollEnum
    };
})();
