'use strict';

exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;

    // URL-encode the `+` character in the request URI
    // See more: https://github.com/rust-lang/crates.io/issues/4891
    if (request.uri.includes("+")) {
        request.uri = request.uri.replace("+", "%2B");
    }

    callback(null, request);
};
