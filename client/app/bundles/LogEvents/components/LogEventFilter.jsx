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
        };
        this.fetchDropdown = this.fetchDropdown.bind(this)
        this.shouldTableUpdate = this.shouldTableUpdate.bind(this)

    }

    shouldTableUpdate(prevState) {
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

        // getTable().loadData();
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

    fetchDropdown(val) {
        let the_data = this.state[val]
        console.log('in fetch host names - ' + val, the_data)
        let rval = []
        rval.push(<option value={'none'}>No Filter</option>)
        if (the_data.constructor == Array) {
            console.log("array for ", val);
            for (let opt of the_data) {
                rval.push(<option value={opt}>{opt}</option>)
            }

        } else {//Object (hash)
            console.log("hash for ", val);
            for (let key in the_data) {
                let value = the_data[key]
                rval.push(<option value={value}>{key}</option>)
            }
        }

        console.log('in fetch host names, returning', rval)
        return rval
    }

    render() {
        // console.log("I am rendering log event filter!");
        // console.log("num_rows state is " + this.state.num_rows);
        // console.log("render logEventFilter! " + this.state.my_module.props.children);
        return (
            <div>
                <table width="50%">
                    <tr>
                        <th className="text-center">Filter Row Count</th>
                        <th className="text-center">Host Name</th>
                        <th className="text-center">Application</th>
                        <th className="text-center">Log Level</th>
                        <th className="text-center">Log Tag</th>
                        <th className="text-center">Acknowledgement</th>
                    </tr>
                    <tr>
                        <td>
                            <select value={this.state.num_rows} onChange={(e) => this.updateNumRows(e.target.value)}
                                    className="form-control">
                                <option value={15}>15 Rows</option>
                                <option value={30}>30 Rows</option>
                                <option value={45}>45 Rows</option>
                                <option value={60}>60 Rows</option>
                            </select>
                        </td>
                        <td>
                            <select value={this.state.hostname} onChange={(e) => this.updateHostname(e.target.value)}
                                    className="form-control">
                                {this.fetchDropdown('hostname_values')}
                            </select>
                        </td>
                        <td>
                            <select value={this.state.application_name}
                                    onChange={(e) => this.updateApplicationName(e.target.value)}
                                    className="form-control">
                                {this.fetchDropdown('application_name_values')}
                            </select>
                        </td>
                        <td>
                            <select value={this.state.level} onChange={(e) => this.updateLogLevel(e.target.value)}
                                    className="form-control">
                                {this.fetchDropdown('log_level_values')}
                            </select>
                        </td>
                        <td>
                            <select value={this.state.tag} onChange={(e) => this.updateTag(e.target.value)}
                                    className="form-control">
                                {this.fetchDropdown('tag_values')}
                            </select>
                        </td>
                        <td>
                            <select value={this.state.acknowledgement}
                                    onChange={(e) => this.updateAckFilter(e.target.value)} className="form-control">
                                <option value={'none'}>No Filter</option>
                                <option value={'ack_only'}>Only Acknowledged Events</option>
                                <option value={'not_ack_only'}>Only Non-Acknowledged Events</option>
                            </select>
                        </td>
                    </tr>
                </table>
            </div>
        );
    }
}
