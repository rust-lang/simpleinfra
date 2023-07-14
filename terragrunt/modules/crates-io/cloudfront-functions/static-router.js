function handler(event) {
    var request = event.request;

    // URL-encode the `+` character in the request URI
    // See more: https://github.com/rust-lang/crates.io/issues/4891
    if (request.uri.includes("+")) {
        request.uri = request.uri.replace("+", "%2B");
    }

    return request;
}
