import React from 'react';

const AckButton = (props) => (
  <td className="btn btn-primary btn-ack" colSpan="2" data-btn_ack_id={props.id}>Acknowledge Event</td>
);

export default AckButton;