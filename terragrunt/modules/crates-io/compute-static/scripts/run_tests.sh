#!/bin/bash

# Start the Python HTTP server in the background, which will act as primary host for requests sent from Rust tests
python3 scripts/test_http_server.py &
SERVER_PID=$!

echo "HTTP server started with PID: $SERVER_PID"

# Run the tests while the HTTP server is active in background
cargo nextest run
CARGO_EXIT_CODE=$?

kill $SERVER_PID
echo "HTTP server stopped"

exit $CARGO_EXIT_CODE