import React from 'react';
import AckButton from './AckButton.jsx';

export default class LogEventRow extends React.Component {
    constructor(props) {
        super(props);
        console.log("My row props are ", props)
        this.paint_ack.bind(this)
    }

    paint_ack(row) {
        let ack = row.acknowledged_by
        return (ack == null ? <AckButton id={row.id}/> : <td>{row.acknowledged_by}</td> )
    }

    render() {
        return (
        <tr>
            <td>{this.props.row.hostname}</td>
            <td>{this.props.row.application_name}</td>
            <td>{this.props.row.level}</td>
            <td>{this.props.row.tag}</td>
            <td>{this.props.row.created_at}</td>
            <td>{this.props.row.message}</td>
            {this.paint_ack(this.props.row)}
        </tr>
        )
    }

}