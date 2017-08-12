import React from 'react';

export default class LogEventRow extends React.Component {
    constructor(props) {
        super(props);
        this.paint_ack.bind(this)
        this.handleAck = this.handleAck.bind(this)
    }

    handleAck() {
        console.log("this is ", this);
        console.log("clicked...", this.props.row.id)
    }

    paint_ack(row) {
        let rval = [];
        let outer = this;
        if (row.acknowledged_by === null) {
            rval.push(<td className="btn btn-primary btn-ack" colSpan="2" onClick={outer.handleAck}>Acknowledge Event</td>)
        } else {
            let style = {
                textAlign: 'right',
                width: '150px'
            }
            rval.push(<td style={style}>Acknowledged By:<br/>Acknowledged On:<br/>Comment:</td>)
            rval.push(<td>{row.acknowledged_by}<br/>{moment(row.acknowledged_on).format('YYYY-MM-DD [at] HH:mm:ss')}<br/></td>)
        }
        return rval;
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
            {this.paint_ack(this.props.row)}
        </tr>
        )
    }

}