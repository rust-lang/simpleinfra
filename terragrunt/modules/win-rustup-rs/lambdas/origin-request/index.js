'use strict';

exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;

    if (request.uri === '/') {
        request.uri = '/i686-pc-windows-msvc/rustup-init.exe';
    } else if (request.uri === '/i686') {
        request.uri = '/i686-pc-windows-msvc/rustup-init.exe';
    } else if (request.uri === '/x86_64') {
        request.uri = '/x86_64-pc-windows-msvc/rustup-init.exe';
    } else if (request.uri === '/aarch64') {
        request.uri = '/aarch64-pc-windows-msvc/rustup-init.exe';
    }
    callback(null, request);
};
