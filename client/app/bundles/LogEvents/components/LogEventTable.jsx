// import PropTypes from 'prop-types';
import React from 'react';

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
        this.state = { my_module: this.props.my_module, row_data: [], num_rows: this.props.num_rows };
        this.loadData.bind(this);
    }

    componentWillMount() {
        this.state.my_module.setTable(this);
    }

    loadData() {
        console.log('num rows is KMA ');
        // this.setState({row_data: ajax_result});
    }

    render() {
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
                    <tr>
                        <td colSpan="8">nothing yet {this.state.num_rows}</td>
                    </tr>
                    </tbody>
                </table>
            </div>
        );
    }
}

