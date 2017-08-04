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
        this.getTable.bind(this);
        this.filter1.bind(this);
        this.filter2.bind(this);
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
        return this.state.table;
    };

    componentDidMount() {
        console.log("componentDidMount logEventsModule! - " + this.props.children);
        // console.log("componentDidMount get filter row num property! - " + this.child_components['greg']);
        // this.getTable().loadData();
    }

    filter1(new_val) {
        console.log("filter 1 new val is " + new_val.num_rows);
        new_val.my_module.getTable().setState({num_rows: new_val.num_rows});
    }

    filter2(new_val) {
        console.log("filter 2 new val is " + new_val);
        new_val.my_module.getTable().setState({filter_rows: new_val.num_rows});
    }


    render() {
        return (
            <div>
                <h3>
                    {this.state.title}
                </h3>
                <LogEventFilter my_module={this} num_rows={15} internal_name="filter1" my_update={this.filter1} />
                <LogEventFilter my_module={this} num_rows={30} internal_name="filter2" my_update={this.filter2} />
                <hr/>
                {/*<LogEventTable my_module={this} num_rows={15}/>*/}
                <LogEventTable my_module={this}/>
            </div>
        );
    }
}
