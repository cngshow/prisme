// import PropTypes from 'prop-types';
import React from 'react';
import LogEventRow from './LogEventRow.jsx';

export default class LogEventTable extends React.Component {
    static propTypes = {
        // row_data: PropTypes.array.isRequired, // this is passed from the Rails view
    };

    /**
     * @param props - Comes from your rails view.
     */
    constructor(props) {
        super(props);
        this.state = {my_module: this.props.my_module, row_data: []};
        this.row_data_to_html.bind(this);
    }

    componentWillMount() {
        this.state.my_module.setTable(this);
    }

    componentDidMount() {
    }

    fetch_rows(filter_state) {
        if (!filter_state || (this.props.my_module.getFilter().state.disabled == true)){
            return//don't poll if an active fetch is happening or we have no state
        }
        let outer = this;
        let fs = {}
        fs['num_rows'] = filter_state.num_rows
        fs['hostname'] = filter_state.hostname
        fs['application_name'] = filter_state.application_name
        fs['tag'] = filter_state.tag
        fs['level'] = filter_state.level
        fs['acknowledgement'] = filter_state.acknowledgement
        //disable state
        this.props.my_module.getFilter().setState({disabled: true})
        $.get(gon.routes.react_log_events_path, fs, function (data) {
            console.log("I got back ", data)
            outer.setState({row_data: data.rows})
            //can this be erbed?
            console.log('hosts are ', data.hostname)
            console.log('tags are ', data.tag)
            console.log('applications are ', data.application_name)
            console.log('log levels are ', data.log_levels)
            console.log('the filter from the table is ', outer.props.my_module.getFilter())
            outer.props.my_module.getFilter().setState({log_level_values: data.log_levels, hostname_values: data.hostname, tag_values: data.tag, application_name_values: data.application_name })
        }).always( function() {
            //set state to enabled
            outer.props.my_module.getFilter().setState({disabled: false})
            outer.props.my_module.getFilter().setState({last_poll: new Date()})
        })
    }

    row_data_to_html(data) {
        let result = [];
        for (let row of data) {
            result.push(<LogEventRow row={row} key={row.id}/>)
        }
        if (result.length == 0) {
            result.push(<tr key="useless"><td colSpan="6">No results found</td></tr>)
        }
        return result
    }

    render() {
        //flash_notify({message: 'I rendered!'}, {type: 'success', delay: 2500, z_index: 9999999});
        return (
            <div>
                <table id="table-log-event-data" className="prisme-table table-striped table-hover">
                    <thead>
                    <tr>
                        <th scope="col" width="15%">Host Name</th>
                        <th scope="col" width="100px">Application</th>
                        <th scope="col" width="100px">Log Level</th>
                        <th scope="col" width="10%">Log Tag</th>
                        <th scope="col" width="100px">Created Date</th>
                        <th scope="col" width="30%">Log Message</th>
                    </tr>
                    </thead>
                    <tbody>
                        {this.row_data_to_html(this.state.row_data)}
                    </tbody>
                </table>
                <br/>
            </div>
        );
    }
}

