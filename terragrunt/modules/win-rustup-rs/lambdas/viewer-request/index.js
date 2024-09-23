function handler(event) {
    var request = event.request;

    if (request.uri === '/') {
        request.uri = '/i686-pc-windows-msvc/rustup-init.exe';
    } else if (request.uri === '/i686') {
        request.uri = '/i686-pc-windows-msvc/rustup-init.exe';
    } else if (request.uri === '/x86_64') {
        request.uri = '/x86_64-pc-windows-msvc/rustup-init.exe';
    } else if (request.uri === '/aarch64') {
        request.uri = '/aarch64-pc-windows-msvc/rustup-init.exe';
    }

    return request;
}
