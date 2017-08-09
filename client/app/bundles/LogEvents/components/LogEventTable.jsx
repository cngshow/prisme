// import PropTypes from 'prop-types';
import React from 'react';
import LogEventRow from './LogEventRow.jsx';

/*
 class LogEventRow extends React.Component {
 render() {
 return (
 <tr>
 <td>{this.props.name}</td>
 <td>{this.props.product.price}</td>
 </tr>
 );
 }
 }
 */

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

    fetch_rows(filter_state) {
        let outer = this;
        let fs = {}
        fs['num_rows'] = filter_state.num_rows
        fs['hostname'] = filter_state.hostname
        fs['application_name'] = filter_state.application_name
        fs['tag'] = filter_state.tag
        fs['level'] = filter_state.level
console.log("filter state is ", fs);

        $.get('react_log_events', fs, function (data) {
            console.log("I got back ", data)
            outer.setState({row_data: data})
        })
    }

    row_data_to_html(data) {
        let result = [];
        for (let row of data) {
            result.push(<LogEventRow row={row} key={row.id}/>)
        }
        if (result.length == 0) {
            result.push(<tr key="useless"><td colSpan="8">nothing yet</td></tr>)
        }
        return result
    }

    render() {
        console.log("I am rendering the data")
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
                        <th scope="col" colSpan="2">Acknowledgement</th>
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

