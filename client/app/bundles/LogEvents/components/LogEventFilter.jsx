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
        };
        this.fetchHostnames = this.fetchHostnames.bind(this)
        this.isChanged = this.isChanged.bind(this)

    }

    isChanged(prevState) {
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
        if (this.isChanged(prevState)) {
            console.log("updating the table")
            this.props.my_update(this.state);
        } else {
            console.log("not updating the table")
        }
    }

    updateNumRows = (num_rows) => {
        this.setState({ num_rows: num_rows });
    };

    updateHostname = (hostname) => {
        this.setState({ hostname: hostname });
    };

    updateApplicationName = (application_name) => {
        this.setState({ application_name: application_name });
    };

    updateLogLevel = (level) => {
        this.setState({ level: level });
    };

    updateTag = (tag) => {
        this.setState({ tag: tag });
    };

    updateAckFilter = (acknowledgement) => {
        this.setState({ acknowledgement: acknowledgement });
    };

    fetchHostnames() {
        console.log('in fetch host names')
        let rval = []
        rval.push(<option value={'none'}>No Filter</option>)
        for (let hostname of this.state.hostname_values) {
            rval.push(<option value={hostname}>{hostname}</option>)
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
                        <select value={this.state.num_rows} onChange={(e) => this.updateNumRows(e.target.value)} className="form-control">
                            <option value={15}>15 Rows</option>
                            <option value={30}>30 Rows</option>
                            <option value={45}>45 Rows</option>
                            <option value={60}>60 Rows</option>
                        </select>
                        </td>
                        <td>
                        <select value={this.state.hostname} onChange={(e) => this.updateHostname(e.target.value)} className="form-control">
                            {console.log("before fetchhostname")}
                            {this.fetchHostnames()}
                            {console.log("after fetchhostname")}
                        </select>
                        </td>
                        <td>
                        <select value={this.state.application_name} onChange={(e) => this.updateApplicationName(e.target.value)} className="form-control">
                            <option value={'none'}>No Filter</option>
                        </select>
                        </td>
                        <td>
                        <select value={this.state.level} onChange={(e) => this.updateLogLevel(e.target.value)} className="form-control">
                            <option value={0}>No Filter</option>
                        </select>
                        </td>
                        <td>
                            <select value={this.state.tag} onChange={(e) => this.updateTag(e.target.value)} className="form-control">
                                <option value={'none'}>No Filter</option>
                                <option value={'LIFE_CYCLE'}>LIFE_CYCLE</option>
                            </select>
                        </td>
                        <td>
                            <select value={this.state.acknowledgement} onChange={(e) => this.updateAckFilter(e.target.value)} className="form-control">
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
