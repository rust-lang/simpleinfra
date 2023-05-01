'use strict';

const CRATE_REDIRECTS = [
    'regex',
    'uuid',
    'time',
    'rustc-serialize',
    'log',
    'getopts',
    'glob',
    'libc',
    'bitflags',
    'rand',
    'tempdir',
    'term',
];

const NOMICON_REDIRECTS = [
    'adv-book',
    'rustonomicon',
    'rustinomicon',
];

const PREFIXES = [
    '',
    '/stable',
    '/nightly',
];

// Generate HTTP redirect response with 301 status code and Location header.
function redirect(url, callback) {
    const response = {
        status: '301',
        statusDescription: 'Moved Permanently',
        headers: {
            location: [{
                key: 'Location',
                value: url,
            }],
        },
    };
    callback(null, response);
}

// Generate HTTP redirect response with 302 status code and Location header
function temp_redirect(url, callback) {
    const response = {
        status: '302',
        statusDescription: 'Found',
        headers: {
            location: [{
                key: 'Location',
                value: url,
            }],
        },
    };
    callback(null, response);
}

exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;
    console.log("request.uri = " + request.uri);

    // Redirect `/` to the rust-lang.org website
    if (request.uri === '/' || request.uri === '/index.html') {
        return temp_redirect('https://www.rust-lang.org/learn', callback);
    }

    // Forward versioned documentation as-is.
    if (/^\/\d/.test(request.uri)) {
        return callback(null, request);
    }

    for (let i = 0; i < CRATE_REDIRECTS.length; i++) {
        const crate = CRATE_REDIRECTS[i];
        if (request.uri.startsWith('/' + crate)) {
            return redirect('https://docs.rs' + request.uri, callback);
        }
    }

    for (let i = 0; i < PREFIXES.length; i++) {
        const prefix = PREFIXES[i];
        const newPrefix = prefix === '' ? '/stable' : prefix;

        // Rewrite `/trpl` to `/stable/book`
        if (request.uri.startsWith(prefix + '/trpl')) {
            const path = request.uri.slice(prefix.length + 5);
            return redirect(newPrefix + '/book' + path, callback);
        }

        // Rewrite `/adv-book` to `/stable/nomicon`
        for (let j = 0; j < NOMICON_REDIRECTS.length; j++) {
            const name = NOMICON_REDIRECTS[j];
            if (request.uri.startsWith(prefix + '/' + name)) {
                const path = request.uri.slice(prefix.length + 1 + name.length);
                return redirect(newPrefix + '/nomicon' + path, callback);
            }
        }
    }

    // Rewrite `/master` to `/nightly`
    if (request.uri.startsWith('/master')) {
        return redirect('/nightly' + request.uri.slice(7), callback);
    }

    // Docs used to be under /doc, so redirect those for now
    if (request.uri.startsWith('/doc')) {
        return redirect(request.uri.slice(4), callback);
    }

    // The `/stable`, `/beta`, and `/nightly` urls are all workable as-is
    if (request.uri.startsWith('/stable') ||
        request.uri.startsWith('/beta') ||
        request.uri.startsWith('/nightly')) {
        return callback(null, request);
    }

    // Special files that are located at `/doc/$file`, they aren't published
    // with all the releases
    if (request.uri === '/favicon.ico' ||
        request.uri === '/google49c5ce1b6ff59509.html') {
        return callback(null, request);
    }

    // Everything else looks under `/stable` automatically for docs
    request.uri = '/stable' + request.uri;
    callback(null, request);
};
