#!/bin/bash

set -euxo pipefail

cd /home/crates-io-downloader

# Refresh crates.io index
if [ -d crates.io-index ]; then
    git -C crates.io-index pull --force
else
    git clone https://github.com/rust-lang/crates.io-index.git
fi

# Re-fetch latest copies of crates into ./all-crates.
# This will automatically skip downloading existing crates.
./.cargo/bin/get-all-crates --index ./crates.io-index --out /var/cache/all-crates
