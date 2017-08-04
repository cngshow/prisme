import PropTypes from 'prop-types';
import React from 'react';

export default class LogEventFilter extends React.Component {
    static propTypes = {
        num_rows: PropTypes.number.isRequired, // this is passed from the Rails view
    };

    /**
     * @param props - Comes from your rails view.
     */
    constructor(props) {
        super(props);
        // How to set initial state in ES6 class syntax
        // https://facebook.github.io/react/docs/reusable-components.html#es6-classes
        // console.log("props in filter " + JSON.stringify(props));
        this.state = { num_rows: this.props.num_rows, my_module: this.props.my_module, internal_name: this.props.internal_name };
        // this.props.my_module.registerComponent({greg: this});
    }

    componentWillMount() {
        // this.props.my_module.setFilter(this);
    }
    componentDidMount() {

        // getTable().loadData();
    }

    componentDidUpdate(prevProps, prevState) {
        this.props.my_update({num_rows: this.state.num_rows, my_module: this.state.my_module});
    }

    updateNumRows = (num_rows) => {
        this.setState({ num_rows });
    };

    render() {
        // console.log("I am rendering log event filter!");
        // console.log("num_rows state is " + this.state.num_rows);
        // console.log("render logEventFilter! " + this.state.my_module.props.children);
        return (
            <div>
                {/*<form >*/}
                    <label htmlFor={this.props.internal_name}>
                        Filter Rows {this.props.internal_name}:
                    </label>
                    <select
                        name={this.props.internal_name}
                        value={this.state.num_rows}
                        onChange={(e) => this.updateNumRows(e.target.value)}
                    >
                        <option value={15}>15 Rows</option>
                        <option value={30}>30 Rows</option>
                        <option value={45}>45 Rows</option>
                        <option value={60}>60 Rows</option>
                    </select>
                {/*</form>*/}
            </div>
        );
    }
}
