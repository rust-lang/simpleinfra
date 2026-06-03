function handler(event) {
    var request = event.request;

    return {
        statusCode: 301,
        statusDescription: "Moved Permanently",
        headers: {
            location: {
                value: "https://rust-lang.org" + request.uri,
            },
            "cache-control": {
                value: "public, max-age=3600",
            },
        },
    };
}
