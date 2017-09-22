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
    this.awaiting_poll_results = false;
    this.timeoutId = -1;
}

Poller.prototype.activate = function (bool) {
    this.active = bool;

    if (!bool && this.timeoutId > 0) {
        console.log("clearing poller timeout " + this.timeoutId.toString());
        clearTimeout(this.timeoutId);
    }
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

Poller.prototype.isAwaitingPollResults = function () {
    return this.awaiting_poll_results;
};

Poller.prototype.poll = function () {
    console.log("in poll for " + this.name);
    var that = this;
    var is_exec_poll_call = false;
    this.awaiting_poll_results = true;

    if (arguments[0] !== undefined) {
        is_exec_poll_call = arguments[0]['execPoll'];
    }

    if (PollMgr.isPollerActive(this.name)) {
        try {
            var params = this.params_callback.call(this);

            $.get(this.ajaxPath, params, function (data) {
                that.callback.call(that, data);
                that.awaiting_poll_results = false;
            });
        }
        catch (e) {
            console.log("exception called in poll.....", e);
            that.awaiting_poll_results = false;
        }
        finally {
            if (PollMgr.isPollerActive(that.name) && !is_exec_poll_call) {
                this.timeoutId = setTimeout(that.poll.bind(that), that.timeout);
            }
        }
    } else {
        this.awaiting_poll_results = false;
    }
};

function FunctionPoller(name, timeout, callback) {
    this.controller_class = $( "body" ).data("poll_controller");
    this.name = name;
    this.timeout = timeout;
    this.callback = callback;
    this.active = false;
    this.timeoutId = -10;
}

FunctionPoller.prototype.activate = function (bool) {
    this.active = bool;

    if (!bool && this.timeoutId > 0) {
        console.log("clearing function timeout " + this.timeoutId.toString());
        clearTimeout(this.timeoutId);
    }
};

FunctionPoller.prototype.setCallback = function (newCallback) {
    this.callback = newCallback;
};

FunctionPoller.prototype.setTimeoutMillis = function (millis) {
    this.timeout = millis;
};

FunctionPoller.prototype.isActive = function () {
    return this.active;
};

FunctionPoller.prototype.poll = function () {
    var ret = false;

    if (PollMgr.isPollerActive(this.name)) {
        ret = true;

        try{
            ret = this.callback.call(this);
        }
        catch(e){
            console.log("exception thrown in poll...", e);
        }
        finally{
            if (ret === true) {
                console.log("trying to call setTimeout....");
                this.timeoutId = setTimeout(this.poll.bind(this), this.timeout);
            } else {
                PollMgr.unregisterPoller(this.name);
            }
        }
    }

    return ret;
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

    // this function is used to immediately call the poll programatically and is used with the row filter onchange
    function execPoll(name) {
        if (isPollerActive(name)) {
            var poller = getPoller(name);

            if (poller !== undefined) {
                // pass execPoll argument to the poll call to prevent the setTimeout from executing as this is actively polling
                // but we are immediately calling the method due to user GUI interaction
                poller.poll({execPoll: true});
            }
        }
    }

    function getPoller(name) {
        var poller;
        $.each(registeredPollers, function (idx, p) {
            if (p.name === name) {
                poller = p;
                return false;//breaks the loop
            }
        });
        return poller;
    }

    function isPollerAwaitingResults(pollName) {
        var ret = false;
        var poller = getPoller(pollName);

        if (poller instanceof Poller) {
            ret = poller.isAwaitingPollResults();
        }
        return ret;
    }

    function reactivatePoller(pollName) {
        var poller = getPoller(pollName);

        if (poller !== undefined && ! poller.isActive()) {
            PollMgr.registerPoller(poller);
        }
    }

    function registerPoller(poller, initial_poll, auto_activate) {
        var pollIt = getPoller(poller.name);
        var found = (pollIt !== undefined);
        var call_poll = (initial_poll === undefined ? true : initial_poll === true);
        var auto_activate = (auto_activate === undefined ? true : auto_activate === true);

        if (found) {
            // if this poll is already active so return in order to not have this polling multiple times
            if (pollIt.isActive()) {
                pollIt.setCallback(poller.callback);
                pollIt.setTimeoutMillis(poller.timeout);
                call_poll = false;

                if (pollIt instanceof Poller) {
                    pollIt.setParamsCallback(poller.params_callback);
                }
            } else {
                if (auto_activate) {
                    pollIt.activate(true);
                }
            }
        } else {
            if (auto_activate) {
                poller.activate(true);
            }
            registeredPollers.push(poller);
            pollIt = poller;
        }

        if (call_poll) {
            pollIt.poll();
        } else {
            poller.timeoutId = setTimeout(poller.poll.bind(poller), poller.timeout);
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
            var poller = getPoller(pollerName);
            if (poller !== undefined) {
                console.log("unregistering poller...", pollerName);
                poller.activate(false);
            }
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

        // function to immediately call the poll method based on user action (for example: changing the row_limit in the filter)
        execPoll: execPoll,

        // function to check if a given poller is currently awaiting results
        isPollerAwaitingResults: isPollerAwaitingResults,

        // function to activate a registered poller
        reactivatePoller: reactivatePoller,
    };
})();
