import ReactOnRails from 'react-on-rails';

import LogEvent from '../components/LogEvents';

// This is how react_on_rails can see the HelloWorld in the browser.
//this registration is set in webpack.config.js
ReactOnRails.register({
    LogEvent,
});
