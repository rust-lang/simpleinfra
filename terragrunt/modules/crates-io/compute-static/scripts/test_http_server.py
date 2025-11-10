from http.server import BaseHTTPRequestHandler, HTTPServer


class MockHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/crates/libgit2-sys/libgit2-sys-0.12.25%2B1.3.0.crate":
            self.send_response(200)
            self.end_headers()
            # The written data is used in Rust tests to verify whether the primary host (this) has actually been queried
            self.wfile.write(b'test_data')
        else:
            self.send_response(404)
            self.end_headers()


HTTPServer(("127.0.0.1", 8080), MockHandler).serve_forever()
