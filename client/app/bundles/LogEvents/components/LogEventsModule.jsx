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

    registerComponent(component) {
        console.log("registering " + component);
        this.child_components.push(component);
    }

    notifyPropChange = (component) => {
        // if (component.state.internal_name === 'gregger') {
            console.log("-------------------- component.state.internal_name is " + component.state.internal_name);
        // }
if (component.state.internal_name === 'filter1') {
    this.getTable().setState({filter_rows: component.state.num_rows});
    return;
} else {
    console.log("------------------------------------------------- in else clause!!!!!!!!!!!");
    this.getTable().setState({num_rows: component.state.num_rows});

}
        // console.log("inspect component is " + this.inspectObject(component));
        // console.log("this.child_components name is " + this.inspectObject(component.context));
        // console.log("notifyPropChange YAY!!!" + component.state.num_rows);
        // console.log("_instance is " + this.inspectObject(component._instance));
        // var greg = parseInt(component.state.num_rows);
        // this.getTable().setState({num_rows: greg, filter_rows: greg + 5})
        // this.setState({title: 'We updated via notifyPropChange with ' + component.state.num_rows})
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
        let table = this.state.table;
        console.log("table is ", table);
        return table;
    };

    componentDidMount() {
        console.log("componentDidMount logEventsModule! - " + this.props.children);
        // console.log("componentDidMount get filter row num property! - " + this.child_components['greg']);
        // this.getTable().loadData();
    }

    load_table(filter_state) {
        console.log("loading table with props...", filter_state);
        filter_state.my_module.getTable().fetch_rows(filter_state)
}

    render() {
        console.log("log event module rendered....");
        return (
            <div>
                <h3>
                    {this.state.title}
                </h3>
                <LogEventFilter
                    my_module={this}
                    num_rows={15}
                    level={0}
                    hostname='none'
                    application_name='none'
                    tag='none'
                    acknowledgement='none'
                    my_update={this.load_table} />
                <hr/>
                <LogEventTable my_module={this}/>
            </div>
        );
    }
}
