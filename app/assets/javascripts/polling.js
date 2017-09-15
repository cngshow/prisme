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
        VUID_REQUESTS: 'vuid_requests',
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
        wait_cursor(true);
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

function Poller(name, timeout, ajaxPath, params_callback, callback) {
    this.controller_class = $( "body" ).data("poll_controller");
    this.name = name;
    this.timeout = timeout;
    this.ajaxPath = ajaxPath;
    this.callback = callback;
    this.params_callback = params_callback;
    this.active = false;
}

Poller.prototype.activate = function (bool) {
    this.active = bool;
};

Poller.prototype.setCallback = function (newCallback) {
    this.callback = newCallback;
};

Poller.prototype.setParamsCallback = function (newCallback) {
    this.params_callback = newCallback;
};

Poller.prototype.setTimeoutMillis = function (millis) {
    this.timeout = millis;
};

Poller.prototype.isActive = function () {
    return this.active;
};

Poller.prototype.poll = function () {
    var that = this;

    if (PollMgr.isPollerActive(this.name)) {
        var params = this.params_callback.call(this);

        $.get(this.ajaxPath, params, function (data) {
            that.callback.call(that, data);

            if (PollMgr.isPollerActive(that.name)) {
                setTimeout(that.poll.bind(that), that.timeout);
            }
        });
    }
};

var PollMgr = (function() {
    var registeredPollers = [];

    function noParams() {
        return {};
    }

    function isPollerActive(name) {
        var ret = false;
        $.each(registeredPollers, function (idx, p) {
            if (p.name === name) {
                ret = p.isActive();
            }
        });
        return ret;
    }

    function registerPoller(poller) {
        var found = false, call_poll = true, pollIt;

        $.each(registeredPollers, function (idx, p) {
            if (p.name === poller.name) {
                found = true;
                pollIt = p;
            }
        });

        if (found) {
            // if this poll is already active so return in order to not have this polling multiple times
            if (pollIt.isActive()) {
                pollIt.setCallback(poller.callback);
                pollIt.setParamsCallback(poller.params_callback);
                pollIt.setTimeoutMillis(poller.timeout);
                call_poll = false;
            } else {
                pollIt.activate(true);
            }
        } else {
            poller.activate(true);
            registeredPollers.push(poller);
            pollIt = poller;
        }

        if (call_poll) {
            pollIt.poll();
        }
    }

    function checkCurrentController() {
        //inactivate all pollers that do not share the controller class for this poller
        var poll_controller = $( "body" ).data("poll_controller");
        $.each(registeredPollers, function (idx, poller) {
            if (poller.controller_class !== poll_controller) {
                poller.activate(false);
            }
        });
    }

    function unregisterPoller(pollerName) {
        if (registeredPollers.length > 0) {
            $.each(registeredPollers, function (idx, poller) {
                if (poller.name === pollerName) {
                    console.log("unregistering poller " + pollerName);
                    poller.activate(false);
                    return false;
                }
            });
        }
    }

    function showPollers() {
        console.log("registeredPollers are...", registeredPollers);
    }

    // Return an object exposed to the public
    return {
        // public methods
        // register a controller and its
        registerPoller: registerPoller,

        // unregister a controller explicitly
        unregisterPoller: unregisterPoller,

        // console log the registered pollers
        showPollers: showPollers,

        // used by Poller to check if it is active and should poll
        isPollerActive: isPollerActive,

        // this is called in order to inactivate pollers who do not share the current poll_controller
        checkCurrentController: checkCurrentController,

        // convenience function when registering a poller when it takes no parameters
        noParams: noParams,
    };
})();
