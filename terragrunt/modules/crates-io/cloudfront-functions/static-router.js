function handler(event) {
    var request = event.request;
    var versionDownloads ='/archive/version-downloads/';

    // URL-encode the `+` character in the request URI
    // See more: https://github.com/rust-lang/crates.io/issues/4891
    if (request.uri.includes("+")) {
        request.uri = request.uri.replace("+", "%2B");
    } else if (request.uri === versionDownloads) {
        request.uri += 'index.html';
        return request;
    } else if (request.uri === '/archive/version-downloads') {
        return permanentRedirect(versionDownloads);
    }

    // cargo versions before 1.24 don't support placeholders in the `dl` field
    // of the index, so we need to rewrite the download URL to point to the
    // crate file instead.
    var match = request.uri.match(/^\/crates\/([^\/]+)\/([^\/]+)\/download$/);
    if (match) {
        var crate = match[1];
        var version = match[2];
        request.uri = `/crates/${crate}/${crate}-${version}.crate`;
    }

    return request;
}

function permanentRedirect(destination) {
    return {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
            'location': { value: destination },
        },
    };
}
