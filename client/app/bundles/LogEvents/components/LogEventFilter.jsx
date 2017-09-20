import PropTypes from 'prop-types';
import React from 'react';

export default class LogEventFilter extends React.Component {
    static propTypes = {
        num_rows: PropTypes.number.isRequired, // this is passed from the Rails view
        level: PropTypes.number.isRequired,
        hostname: PropTypes.string.isRequired,
        application_name: PropTypes.string.isRequired,
        tag: PropTypes.string.isRequired,
        acknowledgement: PropTypes.string.isRequired,
    };

    /**
     * @param props - Comes from your rails view.
     */
    constructor(props) {
        super(props);
        // How to set initial state in ES6 class syntax
        // https://facebook.github.io/react/docs/reusable-components.html#es6-classes
        // console.log("props in filter " + JSON.stringify(props));

        //this code is to prevent people from putting values too low in the prop file
        if (LogEventPollData.polling_interval < 15*1000) {
            LogEventPollData.polling_interval = 60 * 1000;
        }
        if (LogEventPollData.log_event_poller_activity_delta < 2*1000) {
            LogEventPollData.log_event_poller_activity_delta = 10*1000;
        }

        this.state = {
            num_rows: this.props.num_rows,
            hostname: this.props.hostname,
            application_name: this.props.application_name,
            level: this.props.level,
            tag: this.props.tag,
            acknowledgement: this.props.acknowledgement,
            my_module: this.props.my_module,
            hostname_values: [],
            tag_values: [],
            application_name_values: [],
            log_level_values: {},
            disabled: false,
            last_poll: 0,
            ack_values: {'Only Acknowledged Events': 'ack_only', 'Only Non-Acknowledged Events': 'not_ack_only'},
            row_values: {'15 Rows': 15, '30 Rows': 30, '45 Rows': 45, '60 Rows': 60}
        };
        this.fetchDropdown = this.fetchDropdown.bind(this)
        this.fetchDropdownValues = this.fetchDropdownValues.bind(this)
        this.shouldTableUpdate = this.shouldTableUpdate.bind(this)
        this.poll = this.poll.bind(this)
    }

    shouldTableUpdate(prevState) {
        if (this.state.disabled == true){
            return false
        }
        let changed = false
        changed = changed || (prevState.num_rows != this.state.num_rows)
        changed = changed || (prevState.hostname != this.state.hostname)
        changed = changed || (prevState.application_name != this.state.application_name)
        changed = changed || (prevState.level != this.state.level)
        changed = changed || (prevState.tag != this.state.tag)
        changed = changed || (prevState.acknowledgement != this.state.acknowledgement)
        return (changed || (JSON.stringify(this.state.hostname_values) == JSON.stringify([])))
    }

    componentWillMount() {
        this.props.my_module.setFilter(this);
    }

    componentDidMount() {
        console.log("polling interval is ", LogEventPollData.polling_interval);
        PollMgr.registerPoller(new FunctionPoller(LogEventPollData.poll_name, LogEventPollData.polling_interval, this.poll), false);
    }


    poll() {
        if (this.state.disabled === true){
            console.log("Disabled skipping LogEvent poll.");
            //skip this poll
        } else {
            if (((new Date()) - this.state.last_poll) > (LogEventPollData.polling_interval - LogEventPollData.log_event_poller_activity_delta)) {
                console.log("About to do a LogEventPoll",this.state.last_poll);
                this.props.my_update(this.state);
            } else {
                console.log("Skipping this poll, due to previous update.", this.state.last_poll);
            }
        }
        return true;
    }

    componentWillUnmount() {
        console.log("Log Event polling stopped!!!!!");
        PollMgr.unregisterPoller(LogEventPollData.poll_name);
    }

    componentDidUpdate(prevProps, prevState) {
        //do not update if state was added
        if (this.shouldTableUpdate(prevState)) {
            console.log("updating the table")
            this.props.my_update(this.state);
        } else {
            console.log("not updating the table")
        }
    }

    updateNumRows = (num_rows) => {
        this.setState({num_rows: num_rows});
    };

    updateHostname = (hostname) => {
        this.setState({hostname: hostname});
    };

    updateApplicationName = (application_name) => {
        this.setState({application_name: application_name});
    };

    updateLogLevel = (level) => {
        this.setState({level: level});
    };

    updateTag = (tag) => {
        this.setState({tag: tag});
    };

    updateAckFilter = (acknowledgement) => {
        this.setState({acknowledgement: acknowledgement});
    };

    fetchDropdown(type, values_key, callback, add_no_filter) {
        let rval = null
        if (this.state.disabled) {
            rval = (
                <select key={values_key} disabled value={type} onChange={(e) => this[callback](e.target.value)} className="form-control">
                    {this.fetchDropdownValues(values_key, add_no_filter)}
                </select>)
        } else {
            rval = (
                <select key={values_key} value={type} onChange={(e) => this[callback](e.target.value)} className="form-control">
                    {this.fetchDropdownValues(values_key, add_no_filter)}
                </select>)
        }
        return rval
    }

    fetchDropdownValues(val, add_no_filter) {
        let the_data = this.state[val]
        let rval = []
        if (add_no_filter) {
            rval.push(<option key="no_filter_key" value={'none'}>No Filter</option>)
        }
        if (the_data.constructor == Array) {
            for (let opt of the_data) {
                rval.push(<option key={opt} value={opt}>{opt}</option>)
            }

        } else {//Object (hash)
            for (let key in the_data) {
                let value = the_data[key]
                rval.push(<option key={key} value={value}>{key}</option>)
            }
        }
        return rval
    }

    render() {
        return (
            <div>
                <table width="80%" className="filter_padding">
                    <tr>
                        <th className="text-center">Filter Row Count</th>
                        <th className="text-center">Host Name</th>
                        <th className="text-center">Application</th>
                        <th className="text-center">Log Level</th>
                        <th className="text-center">Log Tag</th>
                    </tr>
                    <tr>
                        <td>
                            {this.fetchDropdown(this.state.num_rows, 'row_values', 'updateNumRows', false)}
                        </td>
                        <td>
                            {this.fetchDropdown(this.state.hostname, 'hostname_values', 'updateHostname', true)}
                        </td>
                        <td>
                            {this.fetchDropdown(this.state.application_name, 'application_name_values', 'updateApplicationName', true)}
                        </td>
                        <td>
                            {this.fetchDropdown(this.state.level, 'log_level_values', 'updateLogLevel', true)}
                        </td>
                        <td>
                            {this.fetchDropdown(this.state.tag, 'tag_values', 'updateTag', true)}
                        </td>
                    </tr>
                </table>
            </div>
        );
    }
}
