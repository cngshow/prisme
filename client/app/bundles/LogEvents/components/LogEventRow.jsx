import React from 'react';

export default class LogEventRow extends React.Component {
    constructor(props) {
        super(props);
    }

    render() {
        return (
        <tr className="text-top" key={this.props.row.id}>
            <td>{this.props.row.hostname}</td>
            <td>{this.props.row.application_name}</td>
            <td>{this.props.row.level}</td>
            <td>{this.props.row.tag}</td>
            <td>{moment(this.props.row.created_at).format('YYYY-MM-DD [at] HH:mm:ss')}</td>
            <td>{this.props.row.message}</td>
        </tr>
        )
    }

}