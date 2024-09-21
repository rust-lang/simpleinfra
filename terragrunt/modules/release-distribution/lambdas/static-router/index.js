'use strict';

// Generate HTTP redirect response with 301 status code and Location header.
function redirect(url, body, callback) {
    const response = {
        status: '301',
        statusDescription: 'Moved Permanently',
        headers: {
            location: [{
                key: 'Location',
                value: url,
            }],
        },
        body: body,
    };
    callback(null, response);
}

exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;

    if (/^\/dist\/\d{4}-\d{2}-\d{2}(\/|\/index.html)?$/.test(request.uri)) {
        request.uri = '/list-files.html';
        return callback(null, request);
    }

    // Rewrite `/rustup.sh` to `https://sh.rustup.rs`
    if (/^\/rustup\.sh$/.test(request.uri)) {
        const body = `
#!/bin/bash
echo "The location of rustup.sh has moved."
echo "Run the following command to install from the new location:"
echo "    curl https://sh.rustup.rs -sSf | sh"
`;
        return redirect('https://sh.rustup.rs', body, callback);
    }

    // Links to `/doc/master/*` are probably from old external sources, so send
    // them back through the doc site to take advantage of any helpful error
    // handling that may be defined there
    if (request.uri.startsWith('/doc/master')) {
        // The slice method is used to remove the '/doc/master' prefix from the
        // URI. 11 is the length of '/doc/master'.
        const newUri = 'https://doc.rust-lang.org/stable' + request.uri.slice(11);
        const body = "The documentation now lives under doc.rust-lang.org";
        return redirect(newUri, body, callback);
    }

    callback(null, request);
};
