'use strict';

exports.handler = (event, context, callback) => {
    const response = event.Records[0].cf.response;
    const request = event.Records[0].cf.request;

    // No need to index all our old pre-1.0 documentation
    if (request.uri.startsWith('/0.')) {
        response.headers['x-robots-tag'] = [{
            key:   'X-Robots-Tag', 
            value: "noindex"
        }];
    }

    callback(null, response);
};
