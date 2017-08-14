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
        this.state = {title: this.props.title, child_components: {}};
        this.getTable = this.getTable.bind(this);
        this.load_table = this.load_table.bind(this);
    }

    setFilter(filter) {
        this.setState({filter: filter})
    }

    setTable(table) {
        this.setState({table: table})
    }

    getFilter() {
        return this.state.filter;
    }

    getTable() {
        let table = this.state.table;
        return table;
    };

    load_table(filter_state) {
        filter_state.my_module.getTable().fetch_rows(filter_state)
    }

    render() {
        return (
            <div>
                <h4>
                    {this.state.title}
                </h4>
                <LogEventFilter
                    my_module={this}
                    num_rows={15}
                    level={0}
                    hostname='none'
                    application_name='none'
                    tag='none'
                    acknowledgement='none'
                    my_update={this.load_table}/>
                <hr/>
                <LogEventTable my_module={this}/>
            </div>
        );
    }
}
