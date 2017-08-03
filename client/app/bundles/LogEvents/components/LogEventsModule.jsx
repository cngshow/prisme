import PropTypes from 'prop-types';
import React from 'react';
import LogEventFilter from "./LogEventFilter";
import LogEventTable from "./LogEventTable";

export default class LogEventsModule extends React.Component {
  static propTypes = {
    title: PropTypes.string.isRequired, // this is passed from the Rails view
  };

    /**
   * @param props - Comes from your rails view.
   */
  constructor(props) {
    super(props);
    this.state = {title: this.props.title};
    // this.getTable.bind(this);
    // this.getFilter.bind(this);
  }

  setFilter(filter) {
    this.setState({filter: filter})
  }

  setTable(table) {
    console.log("I am setting table to " + table);
    this.setState({table: table})
  }

  getFilter() {
      return this.state.filter;
  }

  getTable() {
      console.log("calling getTable...returning " + this.state.table);
      return this.state.table;
  };

  componentDidMount() {
    console.log("componentDidMount logEventsModule! - " + this.props.children);
    // this.getTable().loadData();
  }

  render() {
      return (
      <div>
        <h3>
          {this.state.title}
        </h3>
        <LogEventFilter my_module={this} num_rows={15}/>
        <hr />
        <LogEventTable my_module={this} num_rows={15}/>
      </div>
    );
  }
}
