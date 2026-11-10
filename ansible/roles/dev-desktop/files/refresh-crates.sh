#!/bin/bash

set -euo pipefail

export GIT_TERMINAL_PROMPT=0

cd /home/crates-io-downloader

INDEX_DIR=crates.io-index
INDEX_URL=https://github.com/rust-lang/crates.io-index.git

# Refresh crates.io index.
# The upstream index is periodically squashed and force-pushed, so a plain
# `git pull` would fail on unrelated histories. Fetch and hard-reset instead.
if [ -d "$INDEX_DIR/.git" ]; then
    git -C "$INDEX_DIR" fetch origin
    git -C "$INDEX_DIR" reset --hard origin/HEAD
    git -C "$INDEX_DIR" clean -fdx
else
    rm -rf "$INDEX_DIR"
    git clone "$INDEX_URL" "$INDEX_DIR"
fi

# Re-fetch latest copies of crates into /var/cache/all-crates.
# This will automatically skip downloading existing crates.
"$HOME/.cargo/bin/get-all-crates" --index "./$INDEX_DIR" --out /var/cache/all-crates
