import ReactOnRails from 'react-on-rails';

import LogEventsModule from '../components/LogEventsModule';

// This is how react_on_rails can see the HelloWorld in the browser.
//this registration is set in webpack.config.js
ReactOnRails.register({
    LogEventsModule,
});
